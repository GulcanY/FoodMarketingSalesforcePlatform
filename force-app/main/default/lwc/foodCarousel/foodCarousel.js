import { LightningElement } from 'lwc';
import CAROUSEL_IMAGES from '@salesforce/resourceUrl/Home2HomeCarousel';

const INTERVAL_MS = 5000;

// Home page photos (static resource Home2HomeCarousel)
const PHOTOS = [
    { file: 'slide-1.jpg', name: 'Grilled meatballs in pita with onions and parsley' },
    { file: 'slide-2.jpg', name: 'Mediterranean meze platter with hummus, olives and vegetables' },
    { file: 'slide-3.jpg', name: 'Spinach and feta filo pie' },
    { file: 'slide-4.jpg', name: 'Fresh Mediterranean ingredients: seafood, olive oil and artichokes' },
    { file: 'slide-5.jpg', name: 'Eggs baked in tomato sauce with basil' },
    { file: 'slide-6.jpg', name: 'Grilled chicken bowl with quinoa, avocado and vegetables' },
    { file: 'slide-7.jpg', name: 'Chickpea, spinach and feta skillet with flatbread' }
];

// Auto-rotating home page photo carousel.
export default class FoodCarousel extends LightningElement {
    slides = PHOTOS.map((photo, index) => ({
        id: `slide-${index + 1}`,
        name: photo.name,
        imageUrl: `${CAROUSEL_IMAGES}/${photo.file}`
    }));
    current = 0;
    isPlaying = true;
    timerId;

    connectedCallback() {
        const reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        this.isPlaying = !reduceMotion;
        this.restartTimer();
    }

    disconnectedCallback() {
        this.stopTimer();
    }

    get hasSlides() {
        return this.slides.length > 0;
    }

    get hasMultiple() {
        return this.slides.length > 1;
    }

    get viewSlides() {
        return this.slides.map((slide, index) => ({
            ...slide,
            className: index === this.current ? 'slide active' : 'slide',
            ariaHidden: index === this.current ? 'false' : 'true',
            label: `${index + 1} of ${this.slides.length}`
        }));
    }

    get counter() {
        return `${this.current + 1} / ${this.slides.length}`;
    }

    get playPauseLabel() {
        return this.isPlaying ? 'Pause slideshow' : 'Play slideshow';
    }

    get liveMode() {
        // announce slide changes only when the user is controlling them
        return this.isPlaying ? 'off' : 'polite';
    }

    restartTimer() {
        this.stopTimer();
        if (this.isPlaying && this.hasMultiple) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.timerId = setInterval(() => this.show(this.current + 1), INTERVAL_MS);
        }
    }

    stopTimer() {
        if (this.timerId) {
            clearInterval(this.timerId);
            this.timerId = undefined;
        }
    }

    show(index) {
        const count = this.slides.length;
        this.current = ((index % count) + count) % count;
    }

    handlePrevious() {
        this.show(this.current - 1);
        this.restartTimer();
    }

    handleNext() {
        this.show(this.current + 1);
        this.restartTimer();
    }

    handleTogglePlay() {
        this.isPlaying = !this.isPlaying;
        this.restartTimer();
    }
}
