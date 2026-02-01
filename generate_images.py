from PIL import Image, ImageDraw, ImageFont
import os

def create_placeholder(filename, text, color):
    # Create a new image with a solid color
    img = Image.new('RGB', (1080, 1920), color=color)
    d = ImageDraw.Draw(img)
    
    # Simple text (without font file loading to avoid errors, using default bitmap font usually or trying load_default)
    # To make it look better, we can try to load a default font or just draw text small
    # But let's try to draw a large rectangle and text
    
    # Draw some patterns to look less boring
    d.rectangle([(0, 0), (1080, 400)], fill=(0, 0, 0, 50))
    d.rectangle([(0, 1520), (1080, 1920)], fill=(0, 0, 0, 50))
    
    # Save
    path = os.path.join(r"d:\Cricket App Full\Cricket-Coaching-App\assets\images", filename)
    img.save(path)
    print(f"Created {path}")

# Colors for different teams
# England: Blue/Red/White -> Dark Blue background
create_placeholder("welcome_england.png", "England Cricket", (20, 30, 60))

# Sri Lanka: Blue/Yellow -> Royal Blue background
create_placeholder("welcome_srilanka.png", "Sri Lanka Cricket", (20, 40, 100))

# NZ: Black/White/Beige -> Black or Dark Grey background
create_placeholder("welcome_nz.png", "New Zealand Cricket", (30, 30, 30))
