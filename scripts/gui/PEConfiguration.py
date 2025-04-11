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
            "fu_in2": False
        }
        # FU input sources
        self.fu_input_sources = {
            "fu_in1": ["north", "east", "south", "west", "const", "fu"],
            "fu_in2": ["north", "east", "south", "west", "const", "fu"],
            "fu_cin": ["north", "east", "south", "west"]
        }
        self.sel_fu = {
            "fu_in1": 0,
            "fu_in1": 0,
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
        # FU fork sender
        self.fs_fu = 0b000000

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
        self.word0 = 0
        self.word1 = 0
        self.word2 = 0
        self.word3 = 0
        self.word4 = 0

    # PE inputs
    def set_pe_input(self, input):
        if input in self.pe_inputs:
            self.pe_inputs[input] = True
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
            if destination in ['fu_cin','fu_in2', 'fu_in1']:
                self.sel_fu[destination] = self.fu_input_sources[destination].index(source)
                if destination != 'fu_cin':
                    self.fu_inputs[destination] = True
            else:
                self.pe_outputs[destination] = self.pe_output_sources[destination].index(source)
        else:
            raise ValueError(f"Invalid source: {source} or destination: {destination}")

    def get_input_destinations(self, source):
        if source in self.fs_inputs_destinations:
            return (self.fs_inputs[source])
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
    
    def get_output_sources(self, output):
        if output in self.pe_outputs:
            return self.pe_outputs[output]
        else:
            raise ValueError(f"Invalid FU input: {output}")

    def __str__(self):
        active = self.get_active_pe_inputs()
        return f"PE Configuration: \n\tPE inputs: {', '.join(active) if active else 'None active'}"

PE0 = PEConfiguration()
PE0.set_pe_input("north")
PE0.set_pe_input("west")
PE0.set_input_destinations("north", "fu_in1")
PE0.set_input_destinations("north", "south")
PE0.set_input_destinations("west", "fu_in2")
PE0.set_input_destinations("west", "east")
print(PE0.get_fu_sources("fu_in1"))
print(PE0.get_fu_sources("fu_in2"))
print(PE0.get_output_sources("north"))
print(PE0.get_output_sources("east"))
print(PE0.get_output_sources("south"))
print(PE0.get_output_sources("west"))