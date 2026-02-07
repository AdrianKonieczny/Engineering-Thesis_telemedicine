import { LightningElement, api } from 'lwc';
import generateSlots from '@salesforce/apex/TelemedicineController.generateSlotsFromAvailability';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class GenerateSlotsAction extends LightningElement {
    @api recordId; 
    isLoading = false;

    handleGenerate() {
        this.isLoading = true;
        
        generateSlots({ availabilityId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Slots have been generated successfully.', 'success');
                this.closeAction();
            })
            .catch(error => {
                let message = 'Unknown error';
                if (error.body && error.body.message) {
                    message = error.body.message;
                }
                this.showToast('Error', message, 'error');
                this.isLoading = false;
            });
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}