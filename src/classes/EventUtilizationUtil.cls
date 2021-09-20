/**
 * Created by Ankit Srivastava.
 */

public without sharing class EventUtilizationUtil {
    public static void processInsertEvents(List<Event> events) {
        //We are not handling recurring events as part of this PoC code
        List<Event> nonRecurringEvents = removeRecurringEvents(events);

        //Remove events that meet following condition:
        //  Events that are for any User who is not a Service Resource
        Map<Event, ServiceResource> relevantEvents = filterNonRelevantEvents(nonRecurringEvents);

        List<AppointmentScheduleLog> appointmentScheduleLogs = new List<AppointmentScheduleLog>();
        for (Event evt : relevantEvents.keySet()) {
            Date eventDate = getEventDate(evt.StartDateTime, evt.ActivityDate, evt.IsAllDayEvent);
            ServiceResource sr = relevantEvents.get(evt);

            //Get existing AppointmentScheduleAggr record for current event's Service Resource and Date. If no such record exists then create one
            AppointmentScheduleAggr asa = getAppointmentScheduleAggrRecord(sr, eventDate);

            AppointmentScheduleLog asl = new AppointmentScheduleLog();
            asl.ServiceResourceId = sr.Id;
            asl.RelatedRecordId = evt.Id;
            asl.AppointmentDate = eventDate;
            asl.UsageType = 'LightningScheduler';
            asl.IsUsedForResourceUtilization = true;
            asl.AppointmentScheduleAggrId = asa.Id;
            asl.ResourceUtilization = getEventDuration(evt.DurationInMinutes, evt.StartDateTime, evt.EndDateTime, evt.IsAllDayEvent);

            appointmentScheduleLogs.add(asl);
        }
        //Insert all AppointmentScheduleLog record. Rollup to AppointmentScheduleAggr will happen automatically
        insert appointmentScheduleLogs;
    }

    public static void processUpdateEvents(List<Event> previousEvents, List<Event> updatedEvents) {
        //TODO
    }

    public static void processDeleteEvents(List<Event> deletedEvents) {
        //TODO
    }

    public static void processUndeleteEvents(List<Event> undeletedEvents) {
        //TODO
    }

    /*
    This method is used to remove Events without attached user record who is also a service resource
     */
    private static Map<Event, ServiceResource> filterNonRelevantEvents(List<Event> events) {
        Map<Event, ServiceResource> resp = new Map<Event, ServiceResource>();
        if (events != null && events.size() > 0) {
            Set<String> ownerIds = new Set<String>();
            for (Event event : events) {
                ownerIds.add(event.OwnerId);
            }
            ServiceResource[] serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecord.Id IN :ownerIds AND IsActive = TRUE];

            for (Event event : events) {
                for (ServiceResource sr : serviceResources) {
                    if (sr.RelatedRecordId == event.OwnerId) {
                        resp.put(event, sr);
                        break;
                    }
                }
            }
        }

        return resp;
    }

    private static List<Event> removeRecurringEvents(List<Event> events) {
        List<Event> filteredEvents = new List<Event>();
        for (Event e : events) {
            if (!isRecurringEvent(e)) {
                filteredEvents.add(e);
            }
        }
        return filteredEvents;
    }

    private static Boolean isRecurringEvent(Event evt) {
        // https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_event.htm
        return evt.IsRecurrence == true || evt.IsRecurrence2 == true;
    }

    private static Date getEventDate(Datetime startDateTime, Date ActivityDate, Boolean isAllDayEvent) {
        // https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_event.htm
        if (isAllDayEvent) {
            if (startDateTime == null) {
                return ActivityDate;
            }
        }

        return startDateTime.date();
    }

    private static AppointmentScheduleAggr getAppointmentScheduleAggrRecord(ServiceResource sr, Date appointmentDate) {
        AppointmentScheduleAggr[] asa = [SELECT Id FROM AppointmentScheduleAggr WHERE ServiceResource.Id = :sr.Id AND AppointmentDate = :appointmentDate];

        if (asa != null && asa.size() > 0) {
            //Return existing AppointmentScheduleAggr record
            return asa[0];
        }

        AppointmentScheduleAggr asaToInsert = new AppointmentScheduleAggr();
        asaToInsert.AppointmentDate = appointmentDate;
        asaToInsert.ServiceResourceId = sr.Id;
        insert asaToInsert;

        //Return newly created AppointmentScheduleAggr record
        return asaToInsert;
    }

    private static Integer getEventDuration(Integer durationInMinutes, Datetime startDateTime, Datetime endDatetime, Boolean isAllDayEvent) {
        // https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_event.htm
        if (isAllDayEvent) {
            return 1440;
        }

        if (durationInMinutes != null) {
            return durationInMinutes;
        }

        return Integer.valueOf((endDatetime.getTime() / 1000 / 60) - (startDateTime.getTime() / 1000 / 60));
    }
}