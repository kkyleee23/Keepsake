# Mascot art: how new poses are made

New poses are generated with Figma AI (model `gemini-3.1-flash-image`,
1024 x 1024) from the description below, so every pose is the same
character. Only the **Pose** sentence changes. The plain off-white background
is what makes the cutout clean.

> A single cute 3D clay-and-plush style mascot character, full body, centered
> with generous empty margin, on a perfectly plain flat off-white background
> (#F9FAF7), no ground shadow, no text, no border, no props other than those
> described. The character: a small round cream-white (#F2EBDD) fluffy
> creature like a soft puppy, very large round head, long floppy ears hanging
> down both sides of the head, one broad sage-green leaf lying flat on top of
> the head (tilted slightly), two small oval glossy black bead eyes, a tiny
> happy curved mouth, faint pink blush cheeks, short stubby arms and round
> feet, wearing a soft knitted dark sage-green (#6B7F63) scarf around its
> neck. **Pose:** ... Soft matte texture, gentle studio lighting from the top
> left, warm and calm, minimal and clean, high detail.

Then cut out the background with the warmth key (cream fur is warm, the
background is neutral), smooth the outline, and save 640 x 640 PNGs into
`assets/brand/states/`, named after the `MascotPose` value.

Poses made this way: reading, writing, photo, gift, waving, secure, hugging,
celebrating, sleepy. Still from the original sheet: idle, happy, excited,
thinking, wink, sad, surprised, typing, sending, received, working,
uploading, error, offline, done.
