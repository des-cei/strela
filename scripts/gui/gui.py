import tkinter as tk
from PIL import Image, ImageTk

# Load images (all must be the same size and RGBA)
pe_base = Image.open("pe_bound.png").convert("RGBA")
img_north_in = Image.open("pe_n.png").convert("RGBA")
img_east_in = Image.open("pe_e.png").convert("RGBA")
img_south_in = Image.open("pe_s.png").convert("RGBA")
img_west_in = Image.open("pe_w.png").convert("RGBA")

# Function to build combined image based on checkbox state
def update_image():
    combined = pe_base.copy()
    if var_north_in.get():
        combined = Image.alpha_composite(combined, img_north_in)
    if var_east_in.get():
        combined = Image.alpha_composite(combined, img_east_in)
    if var_south_in.get():
        combined = Image.alpha_composite(combined, img_south_in)
    if var_west_in.get():
        combined = Image.alpha_composite(combined, img_west_in)

    tk_img = ImageTk.PhotoImage(combined)
    img_label.config(image=tk_img)
    img_label.image = tk_img  # Keep reference to avoid garbage collection

# Create main window
window = tk.Tk()
window.title("PE Configuration")

# Boolean variables for checkboxes
var_north_in = tk.BooleanVar()
var_east_in = tk.BooleanVar()
var_south_in = tk.BooleanVar()
var_west_in = tk.BooleanVar()

# Create checkboxes
tk.Checkbutton(window, text="North", variable=var_north_in, command=update_image).pack(anchor="w")
tk.Checkbutton(window, text="East", variable=var_east_in, command=update_image).pack(anchor="w")
tk.Checkbutton(window, text="South", variable=var_south_in, command=update_image).pack(anchor="w")
tk.Checkbutton(window, text="West", variable=var_west_in, command=update_image).pack(anchor="w")

# Placeholder image to initialize the label
init_img = ImageTk.PhotoImage(pe_base)
img_label = tk.Label(window, image=init_img)
img_label.image = init_img
img_label.pack(padx=10, pady=10)

# Start the GUI loop
window.mainloop()