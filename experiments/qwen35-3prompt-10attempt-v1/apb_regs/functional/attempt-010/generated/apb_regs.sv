```verilog
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

  // Internal state for register values
  reg_data_t [NoApbRegs-1:0] reg_q;

  // APB Protocol Signals (Standard APB3/2)
  // PSEL: Select signal
  // PENABLE: Enable signal
  // PWRITE: Write direction
  // PADDR: Address
  // PWDATA: Write data
  // PREADY: Ready signal
  // PSLVERR: Slave error response
  // PRESP: Response status (PREADY + PSLVERR)

  logic pselect_i;
  logic penable_i;
  logic pwrite_i;
  logic paddr_i;
  logic pwdata_i;
  logic pready_o;
  logic pslverr_o;

  // Generate APB interface from generic req_t/resp_t
  // Assuming req_t contains {pselect, penable, pwrite, paddr, pwdata}
  // Assuming resp_t contains {pready, pslverr}
  // This mapping is inferred based on standard APB structures.
  // If req_t and resp_t are simple logic, we assume they map directly to the specific signals.
  // However, to be robust with the provided generic types, we assume the testbench drives
  // the specific fields if req_t is a struct, or we assume req_t is a bundle.
  // Given the prompt says "req_i / resp_o use the APB request and response types supplied",
  // we assume req_t is a bundle containing the necessary APB signals.
  
  // Since the exact structure of req_t and resp_t is not defined in the parameter list 
  // (only their types are passed), we must assume the testbench connects them correctly 
  // to the internal logic or that req_t/resp_t are aliases to the standard APB bundles.
  // To make this functional as a standalone module without knowing the exact bundle structure,
  // we will assume req_t maps to the input bundle and resp_t maps to the output bundle.
  // We will use a generic assignment strategy assuming req_t has fields: pselect, penable, pwrite, paddr, pwdata
  // and resp_t has fields: pready, pslverr.
  
  // NOTE: In a real scenario with unknown bundle structures, explicit field names would be needed.
  // Here, we assume the standard APB3/2 bundle structure is used for req_t and resp_t.
  // If req_t is just 'logic', this implementation would need adjustment, but APB implies bundles.
  // We will assume req_t is a bundle with: .pselect, .penable, .pwrite, .paddr, .pwdata
  // and resp_t is a bundle with: .pready, .pslverr
  
  // Extract APB signals from req_i
  // Since we cannot know the exact field names of req_t without a typedef, 
  // we assume the standard naming convention used in most APB wrappers.
  // If req_t is a simple logic, this code will fail to compile unless req_t is a bundle.
  // Given the context of "APB-mapped", it is highly likely req_t is a bundle.
  
  // To handle the generic type parameter safely, we assume the testbench provides the correct bundle.
  // We will use a procedural block to handle the logic.
  
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q <= '0;
    end else begin
      reg_q <= reg_init_i; // Initialize on reset
    end
  end

  // Logic to handle APB transactions
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      pready_o <= 1'b1;
      pslverr_o <= 1'b0;
    end else begin
      // Default ready
      pready_o <= 1'b1;
      pslverr_o <= 1'b0;

      // Check if transaction is enabled and selected
      if (req_i.penable && req_i.pselect) begin
        // Check for write error conditions
        // 1. Address out of bounds
        // 2. Write to read-only register
        
        logic addr_valid;
        logic write_to_ro;
        
        // Calculate register index
        // Address is relative to base_addr_i
        // addr_i = base_addr_i + (reg_idx * AddrOffset)
        // reg_idx = (addr_i - base_addr_i) / AddrOffset
        
        // We need to check if the address falls within the range of registers
        // Range: [base_addr_i, base_addr_i + (NoApbRegs-1)*AddrOffset]
        
        // Since we don't have a direct 'addr_i' input, we assume req_i.paddr contains the absolute address
        // or relative address. Standard APB uses absolute address.
        // Let's assume req_i.paddr is the absolute address.
        
        if (NoApbRegs > 0) begin
          // Calculate offset from base
          logic [ApbAddrWidth-1:0] offset_addr;
          offset_addr = req_i.paddr - base_addr_i;
          
          // Check if offset is negative (should not happen with unsigned math if base <= addr, but safe to check)
          if (offset_addr < 0) begin
            pslverr_o <= 1'b1;
            pready_o <= 1'b0;
          end else begin
            // Check if offset is within valid range
            // Max offset = (NoApbRegs - 1) * AddrOffset
            logic [ApbAddrWidth-1:0] max_offset;
            max_offset = (NoApbRegs - 1) * AddrOffset;
            
            if (offset_addr > max_offset) begin
              pslverr_o <= 1'b1;
              pready_o <= 1'b0;
            end else begin
              // Calculate register index
              logic [ApbAddrWidth-1:0] reg_idx;
              reg_idx = offset_addr / AddrOffset;
              
              // Check if index is within bounds
              if (reg_idx >= NoApbRegs) begin
                pslverr_o <= 1'b1;
                pready_o <= 1'b0;
              end else begin
                // Check if write to read-only
                if (req_i.pwrite && (ReadOnly[reg_idx])) begin
                  pslverr_o <= 1'b1;
                  pready_o <= 1'b0;
                end else begin
                  // Valid transaction
                  if (req_i.pwrite) begin
                    // Write data
                    // Ensure we don't write beyond RegDataWidth if pwdata is wider
                    // Assuming pwdata matches RegDataWidth or is a superset
                    reg_q[reg_idx] <= req_i.pwdata;
                  end
                  // Read operation: do nothing to reg_q, just acknowledge
                  pready_o <= 1'b1;
                end
              end
            end
          end
        end else begin
          // No registers defined
          pslverr_o <= 1'b1;
          pready_o <= 1'b0;
        end
      end else begin
        // Not selected or not enabled
        pready_o <= 1'b1;
        pslverr_o <= 1'b0;
      end
    end
  end

  // Assign outputs based on internal signals
  // Map internal pready/pslverr to resp_o
  // Assuming resp_t is a bundle {pready, pslverr}
  // If resp_t is a single logic, this assignment might need adjustment, 
  // but standard APB response is a 2-bit signal (READY + SLVERR) or separate.
  // Given the parameter type is 'logic', we assume resp_t is a bundle.
  
  // If resp_t is a bundle:
  // resp_o.pready = pready_o;
  // resp_o.pslverr = pslverr_o;
  
  // Since we cannot define bundle members in the output assignment without knowing the structure,
  // we assume the testbench expects the standard APB response bundle.
  // However, to strictly follow the prompt's "output resp_t", we assign the bundle.
  // We will assume resp_t has fields .pready and .pslverr.
  
  // If the types are not bundles, this code will fail. 
  // But given "APB-mapped", bundles are expected.
  // We will use a generic assignment assuming the bundle structure.
  
  // To make this compile generically without knowing the bundle fields, 
  // we assume the standard APB3/2 response bundle structure.
  // If the user's req_t/resp_t are simple logic, this module is not applicable.
  // We proceed assuming bundles.
  
  // Assigning the response bundle
  // Note: In SystemVerilog, if resp_t is a typedef for a bundle, we can assign fields.
  // If resp_t is just 'logic', we cannot assign fields. 
  // The prompt says "parameter type resp_t = logic". This implies resp_t is a type alias.
  // If the alias points to a bundle, we can access fields.
  // We assume the standard APB response bundle: {pready, pslverr}
  
  // Since we don't know the field names of resp_t, we assume the standard naming:
  // .pready and .pslverr.
  
  // However, to be safe against non-bundle types, we will assume the testbench 
  // handles the mapping if resp_t is not a bundle. But for APB, it must be.
  // We will assume resp_t is a bundle with fields .pready and .pslverr.
  
  // If resp_t is a bundle:
  resp_o.pready = pready_o;
  resp_o.pslverr = pslverr_o;

  // Assign register outputs
  reg_q_o = reg_q;

endmodule
```<|im_end|>
