# Copyright 2025 CEI-UPM
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# Daniel Vazquez (daniel.vazquez@upm.es)

import tkinter as tk
import tkinter.ttk as ttk
from PIL import Image, ImageTk
from PEConfiguration import PEConfiguration

# Load images (all must be the same size and RGBA)
pe_base = Image.open("pe_bound.png").convert("RGBA")
img_north_in = Image.open("pe_n.png").convert("RGBA")
img_east_in = Image.open("pe_e.png").convert("RGBA")
img_south_in = Image.open("pe_s.png").convert("RGBA")
img_west_in = Image.open("pe_w.png").convert("RGBA")
img_fu = Image.open("pe_fu.png").convert("RGBA")

# North route images
img_north_1 = Image.open("pe_n_1.png").convert("RGBA")
img_north_2 = Image.open("pe_n_2.png").convert("RGBA")
img_north_3 = Image.open("pe_n_3.png").convert("RGBA")
img_north_4 = Image.open("pe_n_4.png").convert("RGBA")

north_dest_order = ["west", "south", "east", "fu_in1", "fu_in2", "fu_cin"]
north_dest_images = {
    "west": img_north_1,
    "south": img_north_2,
    "east": img_north_4,
    "fu_in1": img_north_3,
    "fu_in2": img_north_3,
    "fu_cin": img_north_3
}

# # East route images
img_east_1 = Image.open("pe_e_1.png").convert("RGBA")
img_east_2 = Image.open("pe_e_2.png").convert("RGBA")
img_east_3 = Image.open("pe_e_3.png").convert("RGBA")
img_east_4 = Image.open("pe_e_4.png").convert("RGBA")

east_dest_order = ["west", "south", "north", "fu_in1", "fu_in2", "fu_cin"]
east_dest_images = {
    "west": img_east_2,
    "south": img_east_4,
    "north": img_east_1,
    "fu_in1": img_east_3,
    "fu_in2": img_east_3,
    "fu_cin": img_east_3
}

# # South route images
img_south_1 = Image.open("pe_s_1.png").convert("RGBA")
img_south_2 = Image.open("pe_s_2.png").convert("RGBA")
img_south_3 = Image.open("pe_s_3.png").convert("RGBA")
img_south_4 = Image.open("pe_s_4.png").convert("RGBA")

south_dest_order = ["west", "east", "north", "fu_in1", "fu_in2", "fu_cin"]
south_dest_images = {
    "west": img_south_4,
    "east": img_south_1,
    "north": img_south_2,
    "fu_in1": img_south_3,
    "fu_in2": img_south_3,
    "fu_cin": img_south_3
}

# # West route images
img_west_1 = Image.open("pe_w_1.png").convert("RGBA")
img_west_2 = Image.open("pe_w_2.png").convert("RGBA")
img_west_3 = Image.open("pe_w_3.png").convert("RGBA")
img_west_4 = Image.open("pe_w_4.png").convert("RGBA")

west_dest_order = ["south", "east", "north", "fu_in1", "fu_in2", "fu_cin"]
west_dest_images = {
    "south": img_west_1,
    "east": img_west_2,
    "north": img_west_4,
    "fu_in1": img_west_3,
    "fu_in2": img_west_3,
    "fu_cin": img_west_3
}

# Create main window
window = tk.Tk()
window.title("PE Configuration")

# Create PE configuration instance
pe_config = PEConfiguration()

# Function to build combined image based on checkbox state
def update_image():
    combined = pe_base.copy()

    # North PE input
    if var_north_in.get():
        pe_config.set_pe_input("north")
        combined = Image.alpha_composite(combined, img_north_in)
        north_dest_frame.pack(side="left")

        for dest, var in north_dest_vars.items():
            if var.get() and dest in north_dest_images:
                pe_config.set_input_destinations("north", dest)
                combined = Image.alpha_composite(combined, north_dest_images[dest])
            else:
                pe_config.unset_input_destinations("north", dest)
    else:
        if pe_config.get_pe_input("north"):
            pe_config.unset_pe_input("north")
        north_dest_frame.pack_forget()

    # East PE input
    if var_east_in.get():
        pe_config.set_pe_input("east")
        combined = Image.alpha_composite(combined, img_east_in)
        east_dest_frame.pack(side="left")

        for dest, var in east_dest_vars.items():
            if var.get() and dest in east_dest_images:
                pe_config.set_input_destinations("east", dest)
                combined = Image.alpha_composite(combined, east_dest_images[dest])
            else:
                pe_config.unset_input_destinations("east", dest)
    else:
        if pe_config.get_pe_input("east"):
            pe_config.unset_pe_input("east")
        east_dest_frame.pack_forget()

    # South PE input
    if var_south_in.get():
        pe_config.set_pe_input("south")
        combined = Image.alpha_composite(combined, img_south_in)
        south_dest_frame.pack(side="left")

        for dest, var in south_dest_vars.items():
            if var.get() and dest in south_dest_images:
                pe_config.set_input_destinations("south", dest)
                combined = Image.alpha_composite(combined, south_dest_images[dest])
            else:
                pe_config.unset_input_destinations("south", dest)
    else:
        if pe_config.get_pe_input("south"):
            pe_config.unset_pe_input("south")
        south_dest_frame.pack_forget()
    
    # West PE input
    if var_west_in.get():
        pe_config.set_pe_input("west")
        combined = Image.alpha_composite(combined, img_west_in)
        west_dest_frame.pack(side="left")

        for dest, var in west_dest_vars.items():
            if var.get() and dest in west_dest_images:
                pe_config.set_input_destinations("west", dest)
                combined = Image.alpha_composite(combined, west_dest_images[dest])
            else:
                pe_config.unset_input_destinations("west", dest)
    else:
        if pe_config.get_pe_input("west"):
            pe_config.unset_pe_input("west")
        west_dest_frame.pack_forget()

    # FU
    if pe_config.get_fu_input("fu_in1") or pe_config.get_fu_input("fu_in2") or pe_config.get_fu_input("fu_cin"):
        combined = Image.alpha_composite(combined, img_fu)

    tk_img = ImageTk.PhotoImage(combined)
    img_label.config(image=tk_img)
    img_label.image = tk_img

    # Update bitstream
    bitstream = pe_config.bitstream()
    bitstream_str = ", ".join(f"W{i}: {word:08X}" for i, word in enumerate(bitstream))
    bitstream_label.config(text=f"Bitstream:\n\n\t{bitstream_str}")

# Boolean variables for checkboxes
var_north_in = tk.BooleanVar()
north_row_frame = tk.Frame(window)
north_row_frame.pack(anchor="w")

var_east_in = tk.BooleanVar()
east_row_frame = tk.Frame(window)
east_row_frame.pack(anchor="w")

var_south_in = tk.BooleanVar()
south_row_frame = tk.Frame(window)
south_row_frame.pack(anchor="w")

var_west_in = tk.BooleanVar()
west_row_frame = tk.Frame(window)
west_row_frame.pack(anchor="w")

# Create checkboxes
tk.Checkbutton(north_row_frame, text=" North", variable=var_north_in, command=update_image).pack(side="left")
tk.Checkbutton(east_row_frame, text=" East ", variable=var_east_in, command=update_image).pack(side="left")
tk.Checkbutton(south_row_frame, text=" South", variable=var_south_in, command=update_image).pack(side="left")
tk.Checkbutton(west_row_frame, text=" West ", variable=var_west_in, command=update_image).pack(side="left")

# Checkboxes for the north destinations
north_dest_frame = tk.Frame(north_row_frame)
separator = ttk.Separator(north_dest_frame, orient="vertical")
separator.pack(side="left", fill="y", padx=5)
north_dest_vars = {}
for dest in north_dest_order:
    var = tk.BooleanVar()
    chk = tk.Checkbutton(north_dest_frame, text=dest, variable=var, command=update_image)
    chk.pack(side="left")
    north_dest_vars[dest] = var

# Checkboxes for the east destinations
east_dest_frame = tk.Frame(east_row_frame)
separator = ttk.Separator(east_dest_frame, orient="vertical")
separator.pack(side="left", fill="y", padx=5)
east_dest_vars = {}
for dest in east_dest_order:
    var = tk.BooleanVar()
    chk = tk.Checkbutton(east_dest_frame, text=dest, variable=var, command=update_image)
    chk.pack(side="left")
    east_dest_vars[dest] = var

# Checkboxes for the south destinations
south_dest_frame = tk.Frame(south_row_frame)
separator = ttk.Separator(south_dest_frame, orient="vertical")
separator.pack(side="left", fill="y", padx=5)
south_dest_vars = {}
for dest in south_dest_order:
    var = tk.BooleanVar()
    chk = tk.Checkbutton(south_dest_frame, text=dest, variable=var, command=update_image)
    chk.pack(side="left")
    south_dest_vars[dest] = var

# Checkboxes for the east destinations
west_dest_frame = tk.Frame(west_row_frame)
separator = ttk.Separator(west_dest_frame, orient="vertical")
separator.pack(side="left", fill="y", padx=5)
west_dest_vars = {}
for dest in west_dest_order:
    var = tk.BooleanVar()
    chk = tk.Checkbutton(west_dest_frame, text=dest, variable=var, command=update_image)
    chk.pack(side="left")
    west_dest_vars[dest] = var

# Separator before image
separator = ttk.Separator(window, orient='horizontal')
separator.pack(fill='x', padx=10, pady=10)

# Placeholder image to initialize the label
init_img = ImageTk.PhotoImage(pe_base)
img_label = tk.Label(window, image=init_img)
img_label.image = init_img
img_label.pack(padx=10, pady=10)

separator = ttk.Separator(window, orient='horizontal')
separator.pack(fill='x', padx=10, pady=10)

# Bitstream
bitstream_label = tk.Label(window, text="Bitstream: N/A", font=("Courier", 10), anchor="w", justify="left")
bitstream_label.pack(fill="x", padx=10, pady=5)
bitstream_str = ", ".join(f"W{i}: {word:08X}" for i, word in enumerate(pe_config.bitstream()))
bitstream_label.config(text=f"Bitstream:\n\n\t{bitstream_str}")

# Start the GUI loop
window.mainloop()

print(pe_config)
