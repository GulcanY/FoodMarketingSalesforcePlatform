import { LightningElement, track } from 'lwc';


export default class BecomeAChef extends LightningElement {
   @track buttonVariant='becomeAChef';
   handleChange(){
    if(this.buttonVariant==='becomeAChef'){
        this.buttonVariant='success';
    }else{
        this.buttonVariant='becomeAChef'
    }

   }
}