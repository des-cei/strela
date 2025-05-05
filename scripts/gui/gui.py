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
img_fu_n = Image.open("pe_fu_n.png").convert("RGBA")
img_fu_e = Image.open("pe_fu_e.png").convert("RGBA")
img_fu_s = Image.open("pe_fu_s.png").convert("RGBA")
img_fu_w = Image.open("pe_fu_w.png").convert("RGBA")

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

fu_operations = ["add", "mul", "sub", "SL", "SRL", "SRA", "AND", "OR", "XOR", ">0", "=0", "mux", "branch", "merge"]

fu_dest_types = ["fu", "fu_delay", "branch1", "branch2"]

def normalize_names(name):
    if name in ["fu_in1", "fu_in2", "fu_cin"]:
        return " " + name[:2].upper() + name[2:]
    if name in ["east", "west"]:
        return " " + name.capitalize() + " "
    return " " + name.capitalize()

# Create PE configuration instance
pe_id = 0
pe_array = [PEConfiguration() for _ in range(16)]
pe_config = pe_array[pe_id]

# PE images
combined = [pe_base.copy() for _ in range(16)]

###########################################################
#  CGRA window
###########################################################

cgra_window = tk.Tk()
cgra_window.title("CGRA configuration")  

rows, cols = 4, 4

# Load initial PE images
pe_tk_images = []
for i in range(16):
    pe_tk_images.append(ImageTk.PhotoImage(combined[i].resize((150, 150), Image.LANCZOS)))
pe_img_refs = []

def update_pe_id(index):
    global pe_id, pe_config
    pe_id = index
    pe_config = pe_array[index]

    update_gui_from_pe()

pe_buttons = []

for row in range(rows):
    for col in range(cols):
        index = col + row * 4
        btn = tk.Button(
            cgra_window,
            image=pe_tk_images[index],
            command=lambda i=index: update_pe_id(i),
            background=cgra_window["background"],
            activebackground=cgra_window["background"],
            borderwidth=0
        )
        btn.grid(row=row, column=col, padx=5, pady=5)
        pe_img_refs.append(pe_tk_images[index])
        pe_buttons.append(btn)

# Update CGRA
def update_pe_images(index):
    updated_img = combined[index].resize((150, 150), Image.LANCZOS)
    tk_img = ImageTk.PhotoImage(updated_img)
    pe_tk_images[index] = tk_img

    pe_buttons[index].config(image=tk_img)
    pe_buttons[index].image = tk_img

def update_gui_from_pe():
    # Actualiza los checkboxes de inputs
    var_north_in.set(pe_config.get_pe_input("north"))
    var_east_in.set(pe_config.get_pe_input("east"))
    var_south_in.set(pe_config.get_pe_input("south"))
    var_west_in.set(pe_config.get_pe_input("west"))

    # Input Destinations
    for dest in north_dest_order:
        north_dest_vars[dest].set(pe_config.get_input_destinations("north", dest))
    for dest in east_dest_order:
        east_dest_vars[dest].set(pe_config.get_input_destinations("east", dest))
    for dest in south_dest_order:
        south_dest_vars[dest].set(pe_config.get_input_destinations("south", dest))
    for dest in west_dest_order:
        west_dest_vars[dest].set(pe_config.get_input_destinations("west", dest))

    # FU operation
    fu_operation.set(pe_config.get_fu_operation())

    # FU extras
    feedback.set(pe_config.get_fu_feedback())
    const_value.set(str(pe_config.get_constant_value()))
    initial_value.set(str(pe_config.get_initial_value()))
    initial_valid.set(pe_config.get_initial_valid())
    delay_value.set(pe_config.get_delay_value())

    # FU destinations
    var_north_out.set(pe_config.get_fu_destinations("north"))
    var_east_out.set(pe_config.get_fu_destinations("east"))
    var_south_out.set(pe_config.get_fu_destinations("south"))
    var_west_out.set(pe_config.get_fu_destinations("west"))

    # FU output type
    if pe_config.get_delay("north"):
        fu_north_type.set("fu_delay")
    elif pe_config.get_branch1_output("north"):
        fu_north_type.set("branch1")
    elif pe_config.get_branch2_output("north"):
        fu_north_type.set("branch2")
    else:
        fu_north_type.set("fu")

    if pe_config.get_delay("east"):
        fu_east_type.set("fu_delay")
    elif pe_config.get_branch1_output("east"):
        fu_east_type.set("branch1")
    elif pe_config.get_branch2_output("east"):
        fu_east_type.set("branch2")
    else:
        fu_east_type.set("fu")

    if pe_config.get_delay("south"):
        fu_south_type.set("fu_delay")
    elif pe_config.get_branch1_output("south"):
        fu_south_type.set("branch1")
    elif pe_config.get_branch2_output("south"):
        fu_south_type.set("branch2")
    else:
        fu_south_type.set("fu")

    if pe_config.get_delay("west"):
        fu_west_type.set("fu_delay")
    elif pe_config.get_branch1_output("west"):
        fu_west_type.set("branch1")
    elif pe_config.get_branch2_output("west"):
        fu_west_type.set("branch2")
    else:
        fu_west_type.set("fu")

    update_image()


###########################################################
#  PE window
###########################################################

pe_window = tk.Toplevel(cgra_window)
pe_window.title("PE Configuration")

def update_bitstream():
    bitstream = pe_config.bitstream()
    bitstream_str = ", ".join(f"W{i}: {word:08X}" for i, word in enumerate(bitstream))
    bitstream_label.config(text=f"Bitstream:\n\n\t{bitstream_str}")

# Function to build combined image based on checkbox state
def update_image():
    combined[pe_id] = pe_base.copy()

    # North PE input
    if var_north_in.get():
        pe_config.set_pe_input("north")
        combined[pe_id] = Image.alpha_composite(combined[pe_id], img_north_in)
        north_dest_frame.pack(side="left")

        for dest, var in north_dest_vars.items():
            if var.get() and dest in north_dest_images:
                pe_config.set_input_destinations("north", dest)
                combined[pe_id] = Image.alpha_composite(combined[pe_id], north_dest_images[dest])
            else:
                pe_config.unset_input_destinations("north", dest)
    else:
        if pe_config.get_pe_input("north"):
            pe_config.unset_pe_input("north")
        north_dest_frame.pack_forget()

    # East PE input
    if var_east_in.get():
        pe_config.set_pe_input("east")
        combined[pe_id] = Image.alpha_composite(combined[pe_id], img_east_in)
        east_dest_frame.pack(side="left")

        for dest, var in east_dest_vars.items():
            if var.get() and dest in east_dest_images:
                pe_config.set_input_destinations("east", dest)
                combined[pe_id] = Image.alpha_composite(combined[pe_id], east_dest_images[dest])
            else:
                pe_config.unset_input_destinations("east", dest)
    else:
        if pe_config.get_pe_input("east"):
            pe_config.unset_pe_input("east")
        east_dest_frame.pack_forget()

    # South PE input
    if var_south_in.get():
        pe_config.set_pe_input("south")
        combined[pe_id] = Image.alpha_composite(combined[pe_id], img_south_in)
        south_dest_frame.pack(side="left")

        for dest, var in south_dest_vars.items():
            if var.get() and dest in south_dest_images:
                pe_config.set_input_destinations("south", dest)
                combined[pe_id] = Image.alpha_composite(combined[pe_id], south_dest_images[dest])
            else:
                pe_config.unset_input_destinations("south", dest)
    else:
        if pe_config.get_pe_input("south"):
            pe_config.unset_pe_input("south")
        south_dest_frame.pack_forget()
    
    # West PE input
    if var_west_in.get():
        pe_config.set_pe_input("west")
        combined[pe_id] = Image.alpha_composite(combined[pe_id], img_west_in)
        west_dest_frame.pack(side="left")

        for dest, var in west_dest_vars.items():
            if var.get() and dest in west_dest_images:
                pe_config.set_input_destinations("west", dest)
                combined[pe_id] = Image.alpha_composite(combined[pe_id], west_dest_images[dest])
            else:
                pe_config.unset_input_destinations("west", dest)
    else:
        if pe_config.get_pe_input("west"):
            pe_config.unset_pe_input("west")
        west_dest_frame.pack_forget()

    # FU
    if pe_config.get_fu_input("fu_in1") or pe_config.get_fu_input("fu_in2") or pe_config.get_fu_input("fu_cin"):
        combined[pe_id] = Image.alpha_composite(combined[pe_id], img_fu)

    # FU destinations
    if var_north_out.get():
        pe_config.set_fu_destinations("north")
        north_fu_dest.pack(side="left")
        combined[pe_id] = Image.alpha_composite(combined[pe_id], img_fu_n)
    else:
        pe_config.unset_fu_destinations("north")
        north_fu_dest.pack_forget()
    
    if var_east_out.get():
        pe_config.set_fu_destinations("east")
        east_fu_dest.pack(side="left")
        combined[pe_id] = Image.alpha_composite(combined[pe_id], img_fu_e)
    else:
        pe_config.unset_fu_destinations("east")
        east_fu_dest.pack_forget()
    
    if var_south_out.get():
        pe_config.set_fu_destinations("south")
        south_fu_dest.pack(side="left")
        combined[pe_id] = Image.alpha_composite(combined[pe_id], img_fu_s)
    else:
        pe_config.unset_fu_destinations("south")
        south_fu_dest.pack_forget()
    
    if var_west_out.get():
        pe_config.set_fu_destinations("west")
        west_fu_dest.pack(side="left")
        combined[pe_id] = Image.alpha_composite(combined[pe_id], img_fu_w)
    else:
        pe_config.unset_fu_destinations("west")
        west_fu_dest.pack_forget()
    
    tk_img = ImageTk.PhotoImage(combined[pe_id])
    img_label.config(image=tk_img)
    img_label.image = tk_img

    update_bitstream()
    update_pe_images(pe_id)

def update_fu_operation(event):
    pe_config.set_fu_operation(fu_operation.get())
    update_bitstream()

def update_feedback():
    if feedback.get():
        pe_config.set_fu_feedback()
    else:
        pe_config.unset_fu_feedback()
    update_bitstream()

def update_constant(*args):
    try:
        value = int(const_value.get(), 0)
        pe_config.set_constant_value(value)
        update_bitstream()
    except ValueError:
        pe_config.set_constant_value(0)
        update_bitstream()
        pass

def update_initial_value(*args):
    try:
        value = int(initial_value.get(), 0)
        pe_config.set_initial_value(value)
        update_bitstream()
    except ValueError:
        pe_config.set_initial_value(0)
        update_bitstream()
        pass

def update_initial_valid():
    if initial_valid.get():
        pe_config.set_initial_valid()
    else:
        pe_config.unset_initial_valid()
    update_bitstream()

def update_delay(*args):
    try:
        value = int(delay_value.get(), 0)
        pe_config.set_delay_value(value)
        update_bitstream()
    except ValueError:
        pe_config.set_delay_value(0)
        update_bitstream()
        pass

def update_fu2north(event):
    pe_config.set_fu_destinations("north")
    if fu_north_type.get() == "fu_delay":
            pe_config.set_delay("north")
    elif fu_north_type.get() == "branch1":
        pe_config.set_branch1_output("north")
    elif fu_north_type.get() == "branch2":
        pe_config.set_branch2_output("north")
    update_bitstream()

def update_fu2east(event):
    pe_config.set_fu_destinations("east")
    if fu_east_type.get() == "fu_delay":
            pe_config.set_delay("east")
    elif fu_east_type.get() == "branch1":
        pe_config.set_branch1_output("east")
    elif fu_east_type.get() == "branch2":
        pe_config.set_branch2_output("east")
    update_bitstream()

def update_fu2south(event):
    pe_config.set_fu_destinations("south")
    if fu_east_type.get() == "fu_delay":
            pe_config.set_delay("south")
    elif fu_east_type.get() == "branch1":
        pe_config.set_branch1_output("south")
    elif fu_east_type.get() == "branch2":
        pe_config.set_branch2_output("south")
    update_bitstream()

def update_fu2west(event):
    pe_config.set_fu_destinations("west")
    if fu_east_type.get() == "fu_delay":
            pe_config.set_delay("west")
    elif fu_east_type.get() == "branch1":
        pe_config.set_branch1_output("west")
    elif fu_east_type.get() == "branch2":
        pe_config.set_branch2_output("west")
    update_bitstream()

# Label
tk.Label(pe_window, text="PE inputs | Input destinations:", font=("Courier", 10), anchor="w", justify="left").pack(fill="x", padx=10, pady=5)

# Boolean variables for checkboxes
var_north_in = tk.BooleanVar()
north_row_frame = tk.Frame(pe_window)
north_row_frame.pack(anchor="w", padx=20)

var_east_in = tk.BooleanVar()
east_row_frame = tk.Frame(pe_window)
east_row_frame.pack(anchor="w", padx=20)

var_south_in = tk.BooleanVar()
south_row_frame = tk.Frame(pe_window)
south_row_frame.pack(anchor="w", padx=20)

var_west_in = tk.BooleanVar()
west_row_frame = tk.Frame(pe_window)
west_row_frame.pack(anchor="w", padx=20)

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
    chk = tk.Checkbutton(north_dest_frame, text=normalize_names(dest), variable=var, command=update_image)
    chk.pack(side="left")
    north_dest_vars[dest] = var

# Checkboxes for the east destinations
east_dest_frame = tk.Frame(east_row_frame)
separator = ttk.Separator(east_dest_frame, orient="vertical")
separator.pack(side="left", fill="y", padx=5)
east_dest_vars = {}
for dest in east_dest_order:
    var = tk.BooleanVar()
    chk = tk.Checkbutton(east_dest_frame, text=normalize_names(dest), variable=var, command=update_image)
    chk.pack(side="left")
    east_dest_vars[dest] = var

# Checkboxes for the south destinations
south_dest_frame = tk.Frame(south_row_frame)
separator = ttk.Separator(south_dest_frame, orient="vertical")
separator.pack(side="left", fill="y", padx=5)
south_dest_vars = {}
for dest in south_dest_order:
    var = tk.BooleanVar()
    chk = tk.Checkbutton(south_dest_frame, text=normalize_names(dest), variable=var, command=update_image)
    chk.pack(side="left")
    south_dest_vars[dest] = var

# Checkboxes for the east destinations
west_dest_frame = tk.Frame(west_row_frame)
separator = ttk.Separator(west_dest_frame, orient="vertical")
separator.pack(side="left", fill="y", padx=5)
west_dest_vars = {}
for dest in west_dest_order:
    var = tk.BooleanVar()
    chk = tk.Checkbutton(west_dest_frame, text=normalize_names(dest), variable=var, command=update_image)
    chk.pack(side="left")
    west_dest_vars[dest] = var

# Separator before FU parameters
separator = ttk.Separator(pe_window, orient='horizontal')
separator.pack(fill='x', padx=10, pady=10)

# FU label
tk.Label(pe_window, text="FU configuration:", font=("Courier", 10), anchor="w", justify="left").pack(fill="x", padx=10, pady=5)

# FU parameters
fu_frame1 = tk.Frame(pe_window)
fu_frame1.pack(padx= 20, pady=5, fill="x")

fu_operation = tk.StringVar()

operations_label = tk.Label(fu_frame1, text="FU operation:")
operations_label.pack(side="left", padx=(5, 5))

operations = ttk.Combobox(fu_frame1, textvariable=fu_operation, values=fu_operations, state='readonly')
operations.current(0)
operations.pack(side="left", padx=(20))

operations.bind("<<ComboboxSelected>>", update_fu_operation)

feedback = tk.BooleanVar()
tk.Checkbutton(fu_frame1, text=" Feedback", variable=feedback, command=update_feedback).pack(side="left", padx=(10))

const_value = tk.StringVar()
initial_value = tk.StringVar()
initial_valid = tk.BooleanVar()

fu_frame2 = tk.Frame(pe_window)
fu_frame2.pack(padx= 20, pady=5, fill="x")
tk.Label(fu_frame2, text="Constant:").pack(side="left", padx=(5, 5))
const_entry = tk.Entry(fu_frame2, textvariable=const_value, width=10)
const_entry.insert(0, "0")
const_entry.pack(side="left", padx=21)

tk.Label(fu_frame2, text="Initial value:").pack(side="left", padx=(5, 5))
initial_value_entry = tk.Entry(fu_frame2, textvariable=initial_value, width=10)
initial_value_entry.insert(0, "0")
initial_value_entry.pack(side="left")

tk.Checkbutton(fu_frame2, text=" Initial valid", variable=initial_valid, command=update_initial_valid).pack(side="left", padx=(10))

const_value.trace_add("write", update_constant)
initial_value.trace_add("write", update_initial_value)

fu_frame3 = tk.Frame(pe_window)
fu_frame3.pack(padx=20 ,pady=5, fill="x")
tk.Label(fu_frame3, text="Delay value:").pack(side="left", padx=(5, 5))
delay_value = tk.StringVar()
delay_entry = tk.Entry(fu_frame3, textvariable=delay_value, width=10)
delay_entry.insert(0, "0")
delay_entry.pack(side="left")
delay_value.trace_add("write", update_delay)

# Separator before FU destinations
separator = ttk.Separator(pe_window, orient='horizontal')
separator.pack(fill='x', padx=10, pady=10)

# FU destinations label
tk.Label(pe_window, text="FU destinations:", font=("Courier", 10), anchor="w", justify="left").pack(fill="x", padx=10, pady=5)

# FU destinations
# Boolean variables for checkboxes
var_north_out = tk.BooleanVar()
north_row_frame2 = tk.Frame(pe_window)
north_row_frame2.pack(anchor="w", padx=20)

var_east_out = tk.BooleanVar()
east_row_frame2 = tk.Frame(pe_window)
east_row_frame2.pack(anchor="w", padx=20)

var_south_out = tk.BooleanVar()
south_row_frame2 = tk.Frame(pe_window)
south_row_frame2.pack(anchor="w", padx=20)

var_west_out = tk.BooleanVar()
west_row_frame2 = tk.Frame(pe_window)
west_row_frame2.pack(anchor="w", padx=20)

# Create checkboxes
tk.Checkbutton(north_row_frame2, text=" North", variable=var_north_out, command=update_image).pack(side="left")
tk.Checkbutton(east_row_frame2, text=" East ", variable=var_east_out, command=update_image).pack(side="left")
tk.Checkbutton(south_row_frame2, text=" South", variable=var_south_out, command=update_image).pack(side="left")
tk.Checkbutton(west_row_frame2, text=" West ", variable=var_west_out, command=update_image).pack(side="left")

# Comboboxx for the north
north_fu_dest = tk.Frame(north_row_frame2)
separator = ttk.Separator(north_fu_dest, orient="vertical")
separator.pack(side="left", fill="y", padx=5)

fu_north_type = tk.StringVar()
fu_north = ttk.Combobox(north_fu_dest, textvariable=fu_north_type, values=fu_dest_types, state='readonly')
fu_north.current(0)
fu_north.pack(side="left", padx=(20))
fu_north.bind("<<ComboboxSelected>>", update_fu2north)

# Comboboxx for the east
east_fu_dest = tk.Frame(east_row_frame2)
separator = ttk.Separator(east_fu_dest, orient="vertical")
separator.pack(side="left", fill="y", padx=5)

fu_east_type = tk.StringVar()
fu_east = ttk.Combobox(east_fu_dest, textvariable=fu_east_type, values=fu_dest_types, state='readonly')
fu_east.current(0)
fu_east.pack(side="left", padx=(20))
fu_east.bind("<<ComboboxSelected>>", update_fu2east)

# Comboboxx for the south
south_fu_dest = tk.Frame(south_row_frame2)
separator = ttk.Separator(south_fu_dest, orient="vertical")
separator.pack(side="left", fill="y", padx=5)

fu_south_type = tk.StringVar()
fu_south = ttk.Combobox(south_fu_dest, textvariable=fu_south_type, values=fu_dest_types, state='readonly')
fu_south.current(0)
fu_south.pack(side="left", padx=(20))
fu_south.bind("<<ComboboxSelected>>", update_fu2south)

# Comboboxx for the west
west_fu_dest = tk.Frame(west_row_frame2)
separator = ttk.Separator(west_fu_dest, orient="vertical")
separator.pack(side="left", fill="y", padx=5)

fu_west_type = tk.StringVar()
fu_west = ttk.Combobox(west_fu_dest, textvariable=fu_west_type, values=fu_dest_types, state='readonly')
fu_west.current(0)
fu_west.pack(side="left", padx=(20))
fu_west.bind("<<ComboboxSelected>>", update_fu2west)

# Separator before image
separator = ttk.Separator(pe_window, orient='horizontal')
separator.pack(fill='x', padx=10, pady=10)

# Placeholder image to initialize the label
init_img = ImageTk.PhotoImage(pe_base)
img_label = tk.Label(pe_window, image=init_img)
img_label.image = init_img
img_label.pack(padx=10, pady=10)

separator = ttk.Separator(pe_window, orient='horizontal')
separator.pack(fill='x', padx=10, pady=10)

# Bitstream
bitstream_label = tk.Label(pe_window, text="Bitstream: N/A", font=("Courier", 10), anchor="w", justify="left")
bitstream_label.pack(fill="x", padx=10, pady=5)
bitstream_str = ", ".join(f"W{i}: {word:08X}" for i, word in enumerate(pe_config.bitstream()))
bitstream_label.config(text=f"Bitstream:\n\n   {bitstream_str}")

# Start the GUI loop
cgra_window.mainloop()

print(pe_config)
