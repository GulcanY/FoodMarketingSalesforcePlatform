import relatedFiles from '@salesforce/apex/ChefCtrl.relatedFiles';
import { LightningElement, api, wire } from 'lwc';


export default class ChefTile extends LightningElement {

    @api chef = {};
    chefImage;
    


    @wire(relatedFiles, {chefImageId: '$chef.Id'})
    photoDetails({data, error}){
        if(data){
            this.chefImage = data;
        }else if(error){
            console.log('ERROR -----', JSON.stringify(error))
        }
    }

    clickHandler(){
        const selectEvent = new CustomEvent('selectchef', {detail: this.chef.Id});
        this.dispatchEvent(selectEvent);
    }
}