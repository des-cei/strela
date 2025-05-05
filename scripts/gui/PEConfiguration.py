# Copyright 2025 CEI-UPM
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# Daniel Vazquez (daniel.vazquez@upm.es)

class PEConfiguration:
    def __init__(self):
        # PE inputs
        # Active inputs
        self.pe_inputs = {
            "north": False,
            "east": False,
            "south": False,
            "west": False
        }
        # Fork senders
        self.fs_inputs_destinations = {
            "north": ['west', 'south', 'east', 'fu_cin', 'fu_in2', 'fu_in1'],
            "east": ['west', 'south', 'north', 'fu_cin', 'fu_in2', 'fu_in1'],
            "south": ['west', 'east', 'north', 'fu_cin', 'fu_in2', 'fu_in1'],
            "west": ['south', 'east', 'north', 'fu_cin', 'fu_in2', 'fu_in1']
        }
        self.fs_inputs_list = {
            "north": [],
            "east": [],
            "south": [],
            "west": []
        }
        self.fs_inputs = {
            "north": 0,
            "east": 0,
            "south": 0,
            "west": 0
        }

        # FU
        # FU inputs
        self.fu_inputs = {
            "fu_in1": False,
            "fu_in2": False,
            "fu_cin": False
        }
        # FU input sources
        self.fu_input_sources = {
            "fu_in1": ["north", "east", "south", "west", "const", "fu"],
            "fu_in2": ["north", "east", "south", "west", "const", "fu"],
            "fu_cin": ["north", "east", "south", "west"]
        }
        self.sel_fu = {
            "fu_in1": 0,
            "fu_in2": 0,
            "fu_cin": 0
        }
        # FU parameters
        self.join_mode = 0
        self.fu_feedback = False
        self.alu_sel = 0
        self.cmp_sel = 0
        self.out_sel = 0
        self.fu_operations = ["add", "mul", "sub", "SL", "SRL", "SRA", "AND",
            "OR", "XOR", ">0", "=0", "mux", "branch", "merge"]
        self.fu_operation = "add"
        self.initial_valid = False
        self.initial_value = 0
        self.constant = 0
        self.delay_value = 0

        # FU outputs - fork sender
        self.fs_fu_destinations = ['west', 'south', 'east', 'north', 'fu_in1', 'fu_in2']
        self.fs_fu = 0

        # PE output source
        self.pe_output_sources = {
            "north": ["east", "south", "west", "fu", "fu_delay", "branch1", "branch2"],
            "east": ["north", "south", "west", "fu", "fu_delay", "branch1", "branch2"],
            "south": ["north", "east", "west", "fu", "fu_delay", "branch1", "branch2"],
            "west": ["north", "east", "south", "fu", "fu_delay", "branch1", "branch2"]
        }
        self.pe_outputs = {
            "north": 0,
            "east": 0,
            "south": 0,
            "west": 0
        }

    # PE inputs
    def set_pe_input(self, input):
        if input in self.pe_inputs:
            self.pe_inputs[input] = True
        else:
            raise ValueError(f"Invalid input: {input}")
    
    def unset_pe_input(self, input):
        if input in self.pe_inputs:
            self.unset_all_input_destinations(input)
            self.pe_inputs[input] = False
        else:
            raise ValueError(f"Invalid input: {input}")

    def get_pe_input(self, input):
        if input in self.pe_inputs:
            return self.pe_inputs[input]
        raise ValueError(f"Invalid input: {input}")

    def get_active_pe_inputs(self):
        return [dir for dir, active in self.pe_inputs.items() if active]

    def set_input_destinations(self, source, destination):
        if source in self.fs_inputs_destinations and destination in self.fs_inputs_destinations[source]:
            if not self.get_pe_input(source):
                raise ValueError(f"Input {source} is not enabled yet")
            self.fs_inputs[source] |= (1 << self.fs_inputs_destinations[source].index(destination))
            if destination not in self.fs_inputs_list[source]:
                self.fs_inputs_list[source].append(destination)
            # Set FU inputs or PE outputs
            if destination in ['fu_cin','fu_in2', 'fu_in1']:
                self.sel_fu[destination] = self.fu_input_sources[destination].index(source)
                self.fu_inputs[destination] = True
            else:
                self.pe_outputs[destination] = self.pe_output_sources[destination].index(source)
        else:
            raise ValueError(f"Invalid source: {source} or destination: {destination}")
    
    def unset_input_destinations(self, source, destination):
        if source in self.fs_inputs_destinations and destination in self.fs_inputs_destinations[source]:
            self.fs_inputs[source] &= ~(1 << self.fs_inputs_destinations[source].index(destination))
            if destination in self.fs_inputs_list[source]:
                self.fs_inputs_list[source].remove(destination)
                if destination in ["fu_in1", "fu_in2", "fu_cin"]:
                    self.sel_fu[destination] = 0
                    self.fu_inputs[destination] = False
                else:
                    self.pe_outputs[destination] = 0
        else:
            raise ValueError(f"Invalid source: {source} or destination: {destination}")
    
    def unset_all_input_destinations(self, source):
        if source in self.fs_inputs_destinations:
            for destination in self.fs_inputs_destinations[source]:
                self.unset_input_destinations(source, destination)
        else:
            raise ValueError(f"Invalid source: {source} or destination: {destination}")

    def get_input_destinations(self, source):
        if source in self.fs_inputs_destinations:
            return self.fs_inputs[source]
        else:
            raise ValueError(f"Invalid source: {source}")
    
    # FU inputs
    def get_fu_input(self, input):
        if input in self.fu_inputs:
            return self.fu_inputs[input]
        else:
            raise ValueError(f"Invalid FU input: {input}")
    
    def get_fu_sources(self, input):
        if input in self.sel_fu:
            return self.sel_fu[input]
        else:
            raise ValueError(f"Invalid FU input: {input}")
    
    # FU
    def set_fu_operation(self, operation):
        if operation in self.fu_operations:
            self.fu_operation = operation

            # Join/Merge
            if operation in [">0", "=0", "mux", "branch"]:
                self.join_mode = 1
            elif operation == "merge":
                self.join_mode = 2

            # ALU
            if operation in ["add", "mul", "sub", "SL", "SRL", "SRA", "AND", "OR", "XOR"]:
                self.alu_sel = self.fu_operations.index(operation)

            # Comparator
            if operation == ">0":
                self.cmp_sel = 1
            
            # Branch bypass
            if operation == "branch":
                if sum(self.fu_inputs.values()) != 1:
                    raise ValueError(f"Too much FU inputs for the branch operation")
                else:
                    if self.fu_inputs["fu_in1"] ==  True:
                        self.sel_fu["fu_in2"] = 4
                    else:
                        self.sel_fu["fu_in1"] = 4

            # FU selector
            if operation in [">0", "=0"]:
                self.out_sel = 1
            elif operation in ["mux", "merge"]:
                self.out_sel = 2
        else:
            raise ValueError(f"Invalid FU operation: {operation}")

    def set_fu_feedback(self):
        if self.fu_operation in ["add", "mul", "sub", "SL", "SRL", "SRA", "AND", "OR", "XOR"]:
            self.fu_feedback = True
        else:
            raise ValueError(f"This operation does not admit feedback")
    
    def unset_fu_feedback(self):
        self.fu_feedback = False

    def set_delay(self, destination):
        if destination in ["north", "east", "south", "west"]:
            self.pe_outputs[destination] = self.pe_output_sources[destination].index("fu_delay")
        else:
            raise ValueError(f"Invalid FU destination: {destination}")
    
    def set_delay_value(self, value):
        if value >= 0:
            self.delay_value = value
        else:
            raise ValueError(f"Invalid delay value {value}")
        
    def set_branch1_output(self, destination):
        if destination in ["north", "east", "south", "west"]:
            self.pe_outputs[destination] = self.pe_output_sources[destination].index("branch1")
        else:
            raise ValueError(f"Invalid FU branch 1 destination: {destination}")
    
    def set_branch2_output(self, destination):
        if destination in ["north", "east", "south", "west"]:
            self.pe_outputs[destination] = self.pe_output_sources[destination].index("branch2")
        else:
            raise ValueError(f"Invalid FU branch 2 destination: {destination}")
        
    def set_constant_value(self, value):
        self.constant = value

    def set_initial_value(self, value):
        self.initial_value = value
    
    def set_initial_valid(self):
        self.initial_valid = True
    
    def unset_initial_valid(self):
        self.initial_valid = False
    
    # FU Outputs
    def set_fu_destinations(self, destination):
        if destination in self.fs_fu_destinations:
            self.fs_fu |= (1 << self.fs_fu_destinations.index(destination))
            if destination in self.fs_fu_destinations[:-2]:
                self.pe_outputs[destination] = self.pe_output_sources[destination].index("fu")
        else:
            raise ValueError(f"Invalid FU destination: {destination}")
        
    def unset_fu_destinations(self, destination):
        if destination in self.fs_fu_destinations:
            self.fs_fu &= ~(1 << self.fs_fu_destinations.index(destination))
            if destination in self.fs_fu_destinations[:-2] and self.pe_outputs[destination] in [3, 4, 5, 6]:
                self.pe_outputs[destination] = 0
        else:
            raise ValueError(f"Invalid FU destination: {destination}")
    
    # PE outputs
    def get_output_sources(self, output):
        if output in self.pe_outputs:
            return self.pe_outputs[output]
        else:
            raise ValueError(f"Invalid PE output: {output}")
    
    def bitstream(self):
        word_1_2 = self.fs_inputs["north"] + (self.fs_inputs["east"] << 6) + (self.fs_inputs["south"] << 12) + (self.fs_inputs["west"] << 18)
        word_1_2 += (self.pe_outputs["north"] << 24) + (self.pe_outputs["east"] << 27) + (self.pe_outputs["south"] << 30) + (self.pe_outputs["west"] << 33)
        word_1_2 += (self.sel_fu["fu_in1"] << 36) + (self.sel_fu["fu_in2"] << 39) + (self.sel_fu["fu_cin"] << 42) + (self.fu_feedback << 44)
        word_1_2 += (self.alu_sel << 45) + (self.cmp_sel << 49) + (self.out_sel << 50)  + (self.fs_fu << 52)
        word_1_2 += (self.join_mode << 58) + (self.initial_valid << 60)

        word_1 = word_1_2 & 0xFFFFFFFF
        word_2 = word_1_2 >> 32
        word_3 = self.initial_value & 0xFFFFFFFF
        word_4 = self.constant & 0xFFFFFFFF
        word_5 = self.delay_value & 0xFFFF
        word_5 += (self.pe_inputs["north"] << 26) + (self.pe_inputs["east"] << 27) + (self.pe_inputs["south"] << 28) + (self.pe_inputs["west"] << 29)
        word_5 += (self.fu_inputs["fu_in1"] << 30) + (self.fu_inputs["fu_in2"] << 31)

        return [word_1, word_2, word_3, word_4, word_5]

    def set_from_bitstream(self, words):
        word_1_2 = (words[1] << 32) | words[0]

        # Fork senders inputs
        self.fs_inputs["north"] = word_1_2 & 0x3F
        self.fs_inputs["east"]  = (word_1_2 >> 6) & 0x3F
        self.fs_inputs["south"] = (word_1_2 >> 12) & 0x3F
        self.fs_inputs["west"]  = (word_1_2 >> 18) & 0x3F

        # PE outputs
        self.pe_outputs["north"] = (word_1_2 >> 24) & 0x7
        self.pe_outputs["east"]  = (word_1_2 >> 27) & 0x7
        self.pe_outputs["south"] = (word_1_2 >> 30) & 0x7
        self.pe_outputs["west"]  = (word_1_2 >> 33) & 0x7

        # FU input selectors
        self.sel_fu["fu_in1"] = (word_1_2 >> 36) & 0x7
        self.sel_fu["fu_in2"] = (word_1_2 >> 39) & 0x7
        self.sel_fu["fu_cin"] = (word_1_2 >> 42) & 0x3

        # FU config
        self.fu_feedback = bool((word_1_2 >> 44) & 0x1)
        self.alu_sel     = (word_1_2 >> 45) & 0xF
        self.cmp_sel     = (word_1_2 >> 49) & 0x1
        self.out_sel     = (word_1_2 >> 50) & 0x3
        self.fs_fu       = (word_1_2 >> 52) & 0x3F
        self.join_mode   = (word_1_2 >> 58) & 0x3
        self.initial_valid = bool((word_1_2 >> 60) & 0x1)

        # Initial value, constant, delay
        self.initial_value = words[2]
        self.constant = words[3]
        self.delay_value = words[4] & 0xFFFF  # 16 bits

        # PE inputs
        self.pe_inputs["north"] = bool((words[4] >> 26) & 0x1)
        self.pe_inputs["east"]  = bool((words[4] >> 27) & 0x1)
        self.pe_inputs["south"] = bool((words[4] >> 28) & 0x1)
        self.pe_inputs["west"]  = bool((words[4] >> 29) & 0x1)

        # FU inputs
        self.fu_inputs["fu_in1"] = bool((words[4] >> 30) & 0x1)
        self.fu_inputs["fu_in2"] = bool((words[4] >> 31) & 0x1)


    def __str__(self):
        pe_inputs = ", ".join(self.get_active_pe_inputs()) or "None"
        fu_inputs = ", ".join(k for k, v in self.fu_inputs.items() if v) or "None"
        fu_sources = ", ".join(f"{k}: {self.fu_input_sources[k][v]}" for k, v in self.sel_fu.items())
        pe_outputs_str = ", ".join(
            f"{k}: {self.pe_output_sources[k][v]}"
            for k, v in self.pe_outputs.items()
            if v != 0
        ) or "None"
        bitstream = self.bitstream()

        return (
            f"PE Configuration:\n"
            f"  - PE inputs: {pe_inputs}\n"
            f"  - FU Inputs: {fu_inputs}\n"
            f"  - FU Sources: {fu_sources}\n"
            f"  - FU Operation: {self.fu_operation}\n"
            f"  - FU Feedback: {self.fu_feedback}, Initial Value: {self.initial_value if self.initial_valid else 'N/A'}\n"
            f"  - FU Constant: {self.constant}, Delay: {self.delay_value}\n"
            f"  - PE Outputs: {pe_outputs_str}\n"
            f"  - Bitstream: 0x{bitstream[0]:08x}, 0x{bitstream[1]:08x}, 0x{bitstream[2]:08x}, 0x{bitstream[3]:08x}, 0x{bitstream[4]:08x}"
        )
