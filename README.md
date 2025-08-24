## 🎰 SlotMachineAnimator Demo

https://github.com/user-attachments/assets/37180687-e78a-43a3-9fbc-15ad213a39d2

This demo video showcases the **SlotMachineAnimator** project, a custom slot machine view built with UIKit, Combine, and SnapKit.  
The animation replicates the feel of a real slot machine, smoothly rolling items until the final result is centered.

### Key Highlights
- Smooth **spinning animation** using `CADisplayLink`
- Dynamic **cell resizing** for the center item
- Automatic **snap-to-center** behavior after scrolling
- Reusable and flexible **UICollectionView + custom flow layout**
- The final stopping item is **randomized** each time

The video demonstrates how the slot machine spins, slows down, and precisely stops on a random target item — creating a polished and realistic slot machine effect.

### SPM
- SnapKit
- SDWebImage

---

### To-do

#### (08.23.2025)
- [x] Refactor the codes (roughly)
  - [x] add backgroundImage with remote image urls
- [x] Make it scrollable by hand
- [x] Print message when slot-machine finish
