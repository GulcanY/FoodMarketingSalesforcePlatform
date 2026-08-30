import { LightningElement, track } from 'lwc';

export default class CustomSearchBar extends LightningElement {
    @track searchTerm = '';
    @track searchResults = [];

    handleInputChange(event) {
        this.searchTerm = event.target.value;
    }

    handleSearch() {
        // Perform search logic here (mock data for example purposes)
        const mockResults = [
            { Food: 'Indian Cuisine' },
            
        ];
        this.searchResults = mockResults.filter(result =>
            result.Name.toLowerCase().includes(this.searchTerm.toLowerCase())
        );
    }
}