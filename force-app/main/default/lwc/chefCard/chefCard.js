import { LightningElement, api, track, wire } from 'lwc';

import CHEF_OBJECT from '@salesforce/schema/Chef__c';
import NAME_FIELD from '@salesforce/schema/Chef__c.Name__c';
import BIO_FIELD from '@salesforce/schema/Chef__c.Bio__c';
import PHONE_FIELD from '@salesforce/schema/Chef__c.Phone__c';
import EMAIL_FIELD from '@salesforce/schema/Chef__c.Email__c';
import ZIPCODE_FIELD from '@salesforce/schema/Chef__c.Zip_Code__c';
import PDPREFERENCES_FIELD from '@salesforce/schema/Chef__c.Pickup_Delivery_Preference__c';
import SOCIALMEDIA_FIELD from '@salesforce/schema/Chef__c.Social_Media_Links__c';
import RATE_FIELD from '@salesforce/schema/Chef__c.AvgRate__c';
import relatedFiles from '@salesforce/apex/ChefCtrl.relatedFiles';
import getRelatedFiles from '@salesforce/apex/ChefCtrl.getRelatedFiles';

import CHEF_CHANNEL from '@salesforce/messageChannel/ChefChannel__c';
import { APPLICATION_SCOPE, MessageContext, subscribe} from 'lightning/messageService';

export default class ChefCard extends LightningElement {

    @api chefRecorId;
    error;
    chefName;
    chefRate;
    chefImage;
    @track foodDetails;  // Track property to hold food images

    objectName = CHEF_OBJECT;
    fields = {
        name:NAME_FIELD,
        bio:BIO_FIELD,
        phone:PHONE_FIELD,
        email:EMAIL_FIELD,
        zip:ZIPCODE_FIELD,
        preference:PDPREFERENCES_FIELD,
        scmedia:SOCIALMEDIA_FIELD,
        rate:RATE_FIELD
    }

    @wire(relatedFiles, {chefImageId: '$chefRecorId'})
    photoDetails({data, error}){
        if(data){
            this.chefImage = data;
        }else if(error){
            console.log('ERROR -----', JSON.stringify(error))
        }
    }

    @wire(getRelatedFiles, { chefId: '$chefRecorId' })
    wiredFoodDetails({ error, data }) {
        if (data) {
            this.foodDetails = data.map(food => {
                return {
                    ...food,
                    url: `/sfc/servlet.shepherd/version/download/${food.latestPublishedVersionId}`
                };
            });
        } else if (error) {
            this.error = error;
        }
    }
    

    @wire(MessageContext)
    context;
    

    connectedCallback(){
        this.subscribeHandler();
    };

    subscribeHandler(){
        subscribe(
            this.context,
            CHEF_CHANNEL,
            (message) => {this.handleMessage(message)},
            {scope: APPLICATION_SCOPE}
        );
    }

    handleMessage(message){
        console.log("Message receive: " + JSON.stringify(message));
        this.chefRecorId = message.chefId;
    }


    
    handleRecordLoaded(event){
        const recordDetail = event.detail.records;
        this.chefName = recordDetail[this.chefRecorId].fields.Name__c.value;
        this.chefRate = recordDetail[this.chefRecorId].fields.AvgRate__c.value;
        // this.chefImage = recordDetail[this.chefRecorId].fields.LinkedEntityId.value;
    };
}