({
    openNewRecord : function(component) {
        const createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "Affiliation__c",
            "defaultFieldValues": {
                'Account__c': component.get('v.recordId')
            }
        });
        createRecordEvent.fire();
    },
    editRecord: function(component, id) {
        const editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": id
        });

        editRecordEvent.fire();
    },
    refreshTable: function(component) {
        component.find("affiliationsGrid").refreshTable();
    }
})