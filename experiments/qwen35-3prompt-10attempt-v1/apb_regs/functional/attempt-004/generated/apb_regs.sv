module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd0,
  parameter int unsigned        ApbAddrWidth = 32'd0,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd0,
  parameter int unsigned        RegDataWidth = 32'd0,
  parameter bit [NoApbRegs-1:0] ReadOnly     = 32'h0,
  parameter type                req_t        = logic,
  parameter type                resp_t       = logic,
  parameter type apb_addr_t                  = logic[ApbAddrWidth-1:0],
  parameter type reg_data_t                  = logic[RegDataWidth-1:0]
) (
  input  logic                      pclk_i,
  input  logic                      preset_ni,
  input  req_t                      req_i,
  output resp_t                     resp_o,
  input  apb_addr_t                 base_addr_i,
  input  reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);

  // Internal logic types
  localparam int unsigned ADDR_WIDTH = ApbAddrWidth;
  localparam int unsigned DATA_WIDTH = RegDataWidth;
  
  // APB Protocol Constants
  localparam int unsigned PADDR_WIDTH = ADDR_WIDTH;
  localparam int unsigned PDATA_WIDTH = DATA_WIDTH;
  
  // APB Signal Types (Standard APB3.0)
  typedef struct packed {
    logic paddr;
    logic pwrite;
    logic pend;
    logic pvalid;
    logic pready;
    logic pprot;
    logic psize;
    logic penable;
    logic psel;
    logic pwrite; // Duplicate in standard, but req_t might differ. We map req_t fields here.
  } apb_if_t;

  // Since req_t and resp_t are generic types passed in, we assume they map to APB signals.
  // We will use the fields from req_i to drive the APB interface logic.
  // Standard APB:
  // - paddr: Address
  // - pwrite: Write enable
  // - pend: Pending (usually 0 for simple regs)
  // - pvalid: Valid
  // - pready: Ready
  // - pprot: Protection
  // - psize: Size
  // - penable: Enable
  // - psel: Select
  // - pwrite: Write (duplicate in standard, often ignored or used for specific protocols)
  
  // We assume req_t has fields: .paddr, .pwrite, .pend, .pvalid, .pprot, .psize, .penable, .psel
  // And resp_t has fields: .pwrite, .pend, .pready, .pprot, .psize, .penable, .psel, .pwrite (response)
  
  // Generate APB Interface
  apb_if_t apb_if;

  assign apb_if.paddr = req_i.paddr;
  assign apb_if.pwrite = req_i.pwrite;
  assign apb_if.pend = req_i.pend;
  assign apb_if.pvalid = req_i.pvalid;
  assign apb_if.pready = req_i.pready;
  assign apb_if.pprot = req_i.pprot;
  assign apb_if.psize = req_i.psize;
  assign apb_if.penable = req_i.penable;
  assign apb_if.psel = req_i.psel;

  // APB Response
  assign resp_o.pwrite = req_i.pwrite; // Echo write
  assign resp_o.pend = req_i.pend;     // Echo pending
  assign resp_o.pready = req_i.pready; // Echo ready
  assign resp_o.pprot = req_i.pprot;   // Echo protection
  assign resp_o.psize = req_i.psize;   // Echo size
  assign resp_o.penable = req_i.penable; // Echo enable
  assign resp_o.psel = req_i.psel;     // Echo select

  // Internal state for register values
  reg_data_t [NoApbRegs-1:0] reg_state;

  // Synchronous Reset Logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_state <= reg_init_i;
    end
  end

  // Address Decoding Logic
  // Calculate the actual register index based on the base address and offset
  // Address = base_addr + (reg_index * AddrOffset)
  // reg_index = (Address - base_addr) / AddrOffset
  
  generate
    if (NoApbRegs > 0) begin : gen_regs
      for (genvar i = 0; i < NoApbRegs; i = i + 1) begin : gen_reg
        // Calculate the expected address for this register
        apb_addr_t expected_addr;
        expected_addr = base_addr_i + (apb_addr_t)(i * AddrOffset);
        
        // Check if the incoming address matches this register
        logic addr_match;
        assign addr_match = (req_i.paddr == expected_addr);
        
        // Determine if this register is read-only
        logic is_read_only;
        assign is_read_only = (ReadOnly[i] == 1'b1);
        
        // Write Logic
        // Only write if:
        // 1. Address matches
        // 2. Write operation (req_i.pwrite == 1)
        // 3. Not read-only
        // 4. APB transaction is valid and ready (pvalid && pready)
        // 5. APB enable is asserted (penable)
        // 6. Protection allows write (pprot == 2'b00 or 2'b01 depending on protocol, assuming 00 for normal)
        // For simplicity, we assume standard APB where pwrite=1 means write.
        
        always_ff @(posedge pclk_i or negedge preset_ni) begin
          if (!preset_ni) begin
            reg_state[i] <= reg_init_i[i];
          end else begin
            if (addr_match && req_i.pwrite && !is_read_only && 
                req_i.pvalid && req_i.pready && req_i.penable && req_i.pprot == 2'b00) begin
              reg_state[i] <= req_i.pdata;
            end
          end
        end
        
        // Read Logic
        // Output the register value if address matches and it's a read operation
        always_comb begin
          reg_data_t current_val;
          current_val = reg_state[i];
          
          if (addr_match && !req_i.pwrite && req_i.pvalid && req_i.pready && req_i.penable) begin
            // Read operation: output current value
            // Note: In APB, the data is driven on the bus, but here we are returning it via reg_q_o
            // The question asks to drive reg_q_o with current values.
            // We will assign the output port directly in the final block or here.
            // However, since reg_q_o is an output array, we need to handle the mapping carefully.
            // Let's assume reg_q_o[i] should reflect the register value when selected.
            // But reg_q_o is an output array of all registers.
            // The requirement says: "Initialize from reg_init_i and drive reg_q_o with current values."
            // This implies reg_q_o[i] always holds the value of register i.
            // The read operation on the bus (req_i) should update the internal state if it's a write.
            // If it's a read, the internal state doesn't change, but the bus (not shown in ports) would see the value.
            // Since we only have reg_q_o as output, we just ensure reg_q_o[i] tracks reg_state[i].
          end
        end
      end
    end
  endgenerate

  // Drive the output ports
  // reg_q_o should always reflect the current state of the registers
  assign reg_q_o = reg_state;

endmodule<|im_end|>
