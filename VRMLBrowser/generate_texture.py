from PIL import Image, ImageDraw

def create_checkerboard(size=(512, 512), num_squares=8):
    image = Image.new("RGB", size, "white")
    draw = ImageDraw.Draw(image)
    
    square_size = size[0] // num_squares
    
    for i in range(num_squares):
        for j in range(num_squares):
            if (i + j) % 2 == 0:
                color = (255, 0, 0) # Red
            else:
                color = (0, 0, 255) # Blue
                
            x0 = i * square_size
            y0 = j * square_size
            x1 = x0 + square_size
            y1 = y0 + square_size
            
            draw.rectangle([x0, y0, x1, y1], fill=color)
            
    # Add some text to indicate orientation
    draw.text((10, 10), "TOP LEFT", fill=(255, 255, 0))
    draw.text((size[0]-60, size[1]-20), "BTM RIGHT", fill=(255, 255, 0))
            
    image.save("test.jpg")
    print("Created test.jpg")

if __name__ == "__main__":
    create_checkerboard()
