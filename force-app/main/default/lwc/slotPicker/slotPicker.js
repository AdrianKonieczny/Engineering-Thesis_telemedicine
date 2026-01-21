import { LightningElement, track } from 'lwc';
import getAvailableSlots from '@salesforce/apex/TelemedicineController.getAvailableSlots';

export default class SlotPicker extends LightningElement {
    @track practitionerId = '';
    @track slots;
    @track error;

    handleIdChange(event) {
        this.practitionerId = event.target.value;
    }

    handleSearch() {
        if (!this.practitionerId) {
            this.error = 'Please enter Practitioner ID';
            return;
        }
        
        getAvailableSlots({ practitionerId: this.practitionerId })
            .then(result => {
                this.slots = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body.message;
                this.slots = undefined;
            });
    }
}