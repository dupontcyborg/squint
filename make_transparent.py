import sys
from PIL import Image

def make_background_transparent(image_path, output_path):
    img = Image.open(image_path)
    img = img.convert("RGBA")
    datas = img.getdata()
    
    newData = []
    # We want to replace pure black pixels with transparent pixels.
    # To avoid replacing dark pixels inside the icon, we can also check if they are near the edges.
    # But a simple color threshold is usually very effective if the background is pure black (0, 0, 0).
    for item in datas:
        # Check if the pixel is extremely close to pure black (r < 10, g < 10, b < 10)
        if item[0] < 5 and item[1] < 5 and item[2] < 5:
            # Make it fully transparent
            newData.append((0, 0, 0, 0))
        else:
            newData.append(item)
            
    img.putdata(newData)
    img.save(output_path, "PNG")
    print(f"Saved transparent image to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 make_transparent.py <input.png> <output.png>")
        sys.exit(1)
    make_background_transparent(sys.argv[1], sys.argv[2])
