import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllChefs from '@salesforce/apex/ChefCtrl.getAllChefs';
import { publish, MessageContext, APPLICATION_SCOPE, subscribe} from 'lightning/messageService';
import CHEF_CHANNEL from '@salesforce/messageChannel/ChefChannel__c';

export default class ChefTileList extends NavigationMixin(LightningElement) {

    chefs;
    selectedChefId;

    @wire(getAllChefs)
    chefsInfo;


    //burdan basladi
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
    //burdan sonrasi...


    chefSelecttHandler(event){
        console.log('Custom Event Received: ', event.detail);
        this.selectedChefId = event.detail;

        //prepare the message
        const message ={
            chefId: this.selectedChefId
        };

        //publish selected chef Id
        publish(
            this.context,
            CHEF_CHANNEL,
            message
        );

        // open the chef's public detail page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.selectedChefId,
                objectApiName: 'Chef__c',
                actionName: 'view'
            }
        });
    }

}