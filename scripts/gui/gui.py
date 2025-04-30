# Copyright 2025 CEI-UPM
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# Daniel Vazquez (daniel.vazquez@upm.es)

import tkinter as tk
from PIL import Image, ImageTk

# Load images (all must be the same size and RGBA)
pe_base = Image.open("pe_bound.png").convert("RGBA")
img_north_in = Image.open("pe_n.png").convert("RGBA")
img_east_in = Image.open("pe_e.png").convert("RGBA")
img_south_in = Image.open("pe_s.png").convert("RGBA")
img_west_in = Image.open("pe_w.png").convert("RGBA")

# North route images
img_north_1 = Image.open("pe_n_1.png").convert("RGBA")
img_north_2 = Image.open("pe_n_2.png").convert("RGBA")
img_north_3 = Image.open("pe_n_3.png").convert("RGBA")
img_north_4 = Image.open("pe_n_4.png").convert("RGBA")

# East route images
img_east_1 = Image.open("pe_e_1.png").convert("RGBA")
img_east_2 = Image.open("pe_e_2.png").convert("RGBA")
img_east_3 = Image.open("pe_e_3.png").convert("RGBA")
img_east_4 = Image.open("pe_e_4.png").convert("RGBA")

# South route images
img_south_1 = Image.open("pe_s_1.png").convert("RGBA")
img_south_2 = Image.open("pe_s_2.png").convert("RGBA")
img_south_3 = Image.open("pe_s_3.png").convert("RGBA")
img_south_4 = Image.open("pe_s_4.png").convert("RGBA")

# West route images
img_west_1 = Image.open("pe_w_1.png").convert("RGBA")
img_west_2 = Image.open("pe_w_2.png").convert("RGBA")
img_west_3 = Image.open("pe_w_3.png").convert("RGBA")
img_west_4 = Image.open("pe_w_4.png").convert("RGBA")

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

# import tkinter as tk
# from tkinter import ttk
# from PIL import Image, ImageTk

# # Function to update the label with the current selected checkboxes
# def update_checkbox_status():
#     selected = []
#     if checkbox_northIn_var.get():
#         selected.append("North")
#     if checkbox_eastIn_var.get():
#         selected.append("East")
#     if checkbox_southIn_var.get():
#         selected.append("South")
#     if checkbox_westIn_var.get():
#         selected.append("West")
    
#     if selected:
#         status_label.config(text="Selected: " + ", ".join(selected))
#     else:
#         status_label.config(text="No options selected")

# # Function to handle dropdown selection
# def fu_selection(event):
#     selected = fu_operation.get()
#     label.config(text=f"You selected: {selected}")

# # Create the main window
# window = tk.Tk()
# window.title("STRELA PE Configuration")
# window.geometry("500x450")

# # Input
# inputs_label = tk.Label(window, text="PE inputs")
# inputs_label.pack(pady=10, anchor="w", padx=20)

# # Checkbox variables
# checkbox_northIn_var = tk.BooleanVar()
# checkbox_eastIn_var = tk.BooleanVar()
# checkbox_southIn_var = tk.BooleanVar()
# checkbox_westIn_var = tk.BooleanVar()

# # Create checkboxes
# checkbox1 = tk.Checkbutton(window, text=" North", variable=checkbox_northIn_var, command=update_checkbox_status)
# checkbox2 = tk.Checkbutton(window, text=" East", variable=checkbox_eastIn_var, command=update_checkbox_status)
# checkbox3 = tk.Checkbutton(window, text=" South", variable=checkbox_southIn_var, command=update_checkbox_status)
# checkbox4 = tk.Checkbutton(window, text=" West", variable=checkbox_westIn_var, command=update_checkbox_status)

# # Place checkboxes
# checkbox1.pack(anchor="w", padx=20)
# checkbox2.pack(anchor="w", padx=20)
# checkbox3.pack(anchor="w", padx=20)
# checkbox4.pack(anchor="w", padx=20)

# # Status label
# status_label = tk.Label(window, text="No options selected")
# status_label.pack(pady=10)

# # FU dropdown options
# # ALU Operation : XOR (8) | OR (7) | AND (6) | SRA (5) | SRL (4) | SL (3) | substract (2) | multiply (1) | add (0)
# fu_operations = ["add", "mul", "sub", "SL", "SRL", "SRA", "AND", "OR", "XOR"]
# fu_operation = tk.StringVar()

# # Dropdown (Combobox)
# dropdown = ttk.Combobox(window, textvariable=fu_operation, values=fu_operations)
# dropdown.current(0)
# dropdown.pack(pady=10)
# dropdown.bind("<<ComboboxSelected>>", fu_selection)

# # Label to show dropdown selection
# label = tk.Label(window, text="Select an option from the dropdown")
# label.pack(pady=10)

# # Load the image
# img = Image.open("pe_bound.png").convert("RGBA")
# img2 = Image.open("pe_n.png").convert("RGBA")

# # test = Image.alpha_composite(img2, img2)
# img2.paste(img)
# img2.show()
# photo = ImageTk.PhotoImage(img2)

# # Create label with the image
# image_label = tk.Label(window, image=photo)
# image_label.image = photo  # Keep a reference so it doesn't get garbage collected
# image_label.place(x=150, y=240)

# # Run the GUI
# # window.mainloop()