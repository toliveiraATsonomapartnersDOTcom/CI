import { LightningElement, api, track, wire } from 'lwc';
import retrieveAffiliationsTableData from '@salesforce/apex/AffiliationsGridController.retrieveAffiliationsTableData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

const actions = {
    view: {
        label: 'View',
        name: 'view'
    },
    edit: {
        label: 'Edit',
        name: 'edit'
    }
};

export default class AffiliationsGrid extends NavigationMixin(LightningElement) {
    @api flexipageRegionWidth;
    @api recordId;
    @api filteredTypes;
    @api excludedTypes;
    @api fieldSet 
    @api componentTitle;
    @track tableData;
    @track columns;
    columnsByName;
    @track displaySpinner = true;;
    @track sortedBy ='';
    @track sortDirection = '';
    @track moreRecords = false;
    @track errorMessage;
    retrievedData;

    @api
    refreshTable() {
        this.displaySpinner = true;
        const self = this;
        refreshApex(this.retrievedData);
    }

    @wire(retrieveAffiliationsTableData, {accountId: '$recordId', filteredTypes: '$coalescedFilterTypes' ,excludedTypes: '$coalescedExcludedTypes', fieldSet: '$fieldSet'})
    retrieveTableData({error, data}) {
        this.displaySpinner = false;
        if (data) {
            this.retrievedData = arguments[0];
            const columns = [];
            this.tableData = JSON.parse(data.Affiliations);
            this.moreRecords = data.MoreRecords;
            
            const columnsByName = {};
            for (let i = 0; i < data.Columns.length; i++) {
                const column = data.Columns[i];
                columnsByName[column.fieldName] = column;
                columns.push(column);
            }

            columns.push({
                type: 'action',
                typeAttributes: {rowActions: this.getRowActions}
            });

            this.columns = columns;
            this.columnsByName = columnsByName;
        } 
        else if (error) {
            let errorMessage;
            if (Array.isArray(error.body)) {
                errorMessage = error.body.map(e => e.message).join(', ');
            } 
            else if (typeof error.body.message === 'string') {
                errorMessage = error.body.message;
            }

            this.displayErrorToast(errorMessage || 'Unknown error');
            this.errorMessage = errorMessage;
        }
    }

    connectedCallback() {
        if (!this.recordId) {
            this.displayErrorToast('The current record cannot be found. Data will not be loaded.')
            
        }
    }

    renderedCallback() {
        var gridContainer = this.template.querySelector('.grid-container');
        if (gridContainer && gridContainer.offsetHeight >= 300) {
            gridContainer.style.height = '300px';
        }
    }

    displayErrorToast(message) {
        const errorEvent = new ShowToastEvent({
            title: 'Unexpected Error in Affiliations List',
            message: message,
            variant: 'error'
        });

        this.dispatchEvent(errorEvent);
    }

    updateSorting (event) {
        this.sortedBy = event.detail.fieldName;
    
        const sortDirection = event.detail.sortDirection;
        this.sortDirection = sortDirection;
        
        const sortedColumn = this.columnsByName[this.sortedBy];
        const sortField = sortedColumn && sortedColumn.typeAttributes && 
            sortedColumn.typeAttributes.label && sortedColumn.typeAttributes.label.fieldName
            ? sortedColumn.typeAttributes.label.fieldName
            : this.sortedBy;
        
        // The slice method is used to clone the array which causes tableData to mutate and redraw
        // the component
        this.tableData = this.tableData.sort(function(record1, record2) {
            const value1 = record1[sortField] || '';
            const value2 = record2[sortField] || '';
            const ascendingSort = sortDirection === 'asc';

            if (value1 < value2) {
                return ascendingSort 
                       ? -1
                       : 1;
            }
            else if (value1 > value2){
                return ascendingSort
                       ? 1
                       : -1;
            }

            return 0;
        }).slice();
    }

    openNewAffiliationForm() {
        const newClickEvent = new CustomEvent('newclick');
        this.dispatchEvent(newClickEvent);
    }

    get recordCount() {
        if (this.isSmall) {
            return this.tableData && this.tableData.length || 0;
        }

        if (!this.tableData || !this.tableData.length) {
            return '0 items';
        }
        if (this.tableData.length === 1) {
            return '1 item'
        }

        return this.tableData.length + ' items';
    }

    get moreRecordsMessage() {
        const message = this.isSmall
                        ? '+'
                        : '(More records available than shown)';
                        
        return this.moreRecords
               ? message
               : null; 
    }

    get sortedByMessage() {
        const sortedLabel = this.columnsByName && this.columnsByName[this.sortedBy] &&
            this.columnsByName[this.sortedBy].label;
        
        if (sortedLabel) {
            return '• Sorted by ' + sortedLabel;
        }

        return '';
    }

    get isSmall() {
        return this.flexipageRegionWidth && 
            this.flexipageRegionWidth.toLowerCase() === 'small';
    }

    get wrapperClass() {
        return this.isSmall 
               ? '' 
               : 'card-wrapper';
    }

    get titlewrapperClass() {
        return this.isSmall 
               ? '' 
               : 'title-card-wrapper';
    }

    // Wire Services will not run if a null value is passed to them. 
    // This property makes sure nulls are converted to an empty string so that the Wire Service
    // always runs regardless of if a value is specified
    get coalescedFilterTypes() {
        return this.filteredTypes || '';
    }

    get coalescedExcludedTypes() {
        return this.excludedTypes || '';
    }

    getRowActions(row, doneCallback) {
        const rowActions = [];
        rowActions.push(actions.view);
        if (row.HasEditAccess) {
            rowActions.push(actions.edit);
        }

        doneCallback(rowActions);
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        let editEvent;
        switch(action.name) {
            case actions.view.name:
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: row.Id,
                            actionName: 'view'
                        }
                    });
                break;
            case actions.edit.name:
                editEvent = new CustomEvent('editclick', {detail: {id: row.Id}});
                this.dispatchEvent(editEvent);
                break;
            default:
                break;
        }
    }
}