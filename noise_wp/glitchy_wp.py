import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import random
import math

def create_glitch_art(width=1920, height=1080, filename="dark_glitch_wallpaper.png"):
    # Create base image (black)
    base = np.zeros((height, width, 3), dtype=np.uint8)

    # Add noise texture
    noise = np.random.rand(height, width)
    for y in range(height):
        for x in range(width):
            if noise[y, x] > 0.65:
                intensity = (noise[y, x] - 0.65) * 3.3 * 45
                # Teal/green colors
                base[y, x, 1] = min(255, int(intensity * 1.2))  # Green channel
                base[y, x, 2] = min(255, int(intensity))        # Blue channel

    # Add finer grain noise
    fine_noise = np.random.rand(height, width)
    for y in range(height):
        for x in range(width):
            if fine_noise[y, x] > 0.9:
                base[y, x, 1] = min(255, base[y, x, 1] + random.randint(15, 40))
                base[y, x, 2] = min(255, base[y, x, 2] + random.randint(10, 30))

    # Convert to PIL for easier manipulation
    img = Image.fromarray(base)
    draw = ImageDraw.Draw(img)

    # Add noise specks
    for _ in range(4000):  # Increased from 3000 to 4000
        x = random.randint(0, width - 1)
        y = random.randint(0, height - 1)
        size = random.randint(1, 2)
        brightness = random.randint(20, 90)

        color = (0,
                random.randint(brightness, brightness+40),
                random.randint(brightness-20, brightness+20))

        if size == 1:
            img.putpixel((x, y), color)
        else:
            draw.rectangle([x, y, x+size-1, y+size-1], fill=color)

    # Distortion waves
    distorted = Image.new('RGB', (width, height), (0, 0, 0))

    for y in range(height):
        wave = math.sin(y * 0.08) * 3
        for x in range(width):
            try:
                # Source coordinates with wave distortion
                src_x = int(x + wave)
                src_y = y

                if 0 <= src_x < width and 0 <= src_y < height:
                    distorted.putpixel((x, y), img.getpixel((src_x, src_y)))
            except:
                pass

    img = distorted

    # Add scan lines (subtle alternating pattern)
    for y in range(0, height, 3):  # Changed from every 2 to every 3 lines
        for x in range(width):
            pixel = list(img.getpixel((x, y)))
            # Darken slightly
            pixel = [max(0, val - 8) for val in pixel]  # Reduced from 10 to 8
            img.putpixel((x, y), tuple(pixel))

    # Enhance contrast
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(1.2)

    # Add vertical glitchy elements
    for _ in range(random.randint(10, 20)):  # Increased from 5-12 to 10-20
        x_pos = random.randint(0, width)
        height_slice = random.randint(50, 200)
        slice_width = random.randint(1, 3)
        y_start = random.randint(0, height - height_slice)

        # Extract a slice
        slice_img = img.crop((x_pos, y_start, x_pos + slice_width, y_start + height_slice))

        # Offset it
        new_y = y_start + random.randint(-50, 50)
        new_y = max(0, min(height - height_slice, new_y))

        # Paste it back with an offset
        img.paste(slice_img, (x_pos, new_y))

    # Save the result
    img.save(filename)
    return img

# Generate the wallpaper
wallpaper = create_glitch_art()
print("Wallpaper created successfully!")
