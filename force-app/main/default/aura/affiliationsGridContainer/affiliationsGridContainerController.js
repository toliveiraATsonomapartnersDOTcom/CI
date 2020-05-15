({
    openNewRecord : function(component, event, helper) {
        helper.openNewRecord(component);
    },
    editRecord: function(component, event, helper) {
        helper.editRecord(component, event.getParam("id"));
    },
    handleSaveSuccess: function(component, event, helper) {
        helper.refreshTable(component);
    },
    handleRefreshedView: function(component, event, helper) {
        helper.refreshTable(component);
    },
})