/**
 * Created by Ankit Srivastava.
 */

trigger EventUtilization on Event (after insert, after update, after delete, after undelete) {
    if (Trigger.isInsert) {
        List<Event> events = Trigger.new;
        //Insert records in AppointmentScheduleLog and AppointmentScheduleAggr entities for all newly created Events
        EventUtilizationUtil.processInsertEvents(events);
    } else if (Trigger.isUpdate) {
        List<Event> previousEvents = Trigger.old;
        List<Event> updatedEvents = Trigger.new;
        //Modify records in AppointmentScheduleLog and AppointmentScheduleAggr entities for all updated Events
        EventUtilizationUtil.processUpdateEvents(previousEvents, updatedEvents);
    } else if (Trigger.isDelete) {
        List<Event> deletedEvents = Trigger.old;
        //Delete records from AppointmentScheduleLog entity for all deleted events
        EventUtilizationUtil.processDeleteEvents(deletedEvents);
    } else if (Trigger.isUndelete) {
        List<Event> undeletedEvents = Trigger.new;
        //Insert records in AppointmentScheduleLog and AppointmentScheduleAggr entity for all Events removed from Recycle Bin
        EventUtilizationUtil.processUndeleteEvents(undeletedEvents);
    }
}