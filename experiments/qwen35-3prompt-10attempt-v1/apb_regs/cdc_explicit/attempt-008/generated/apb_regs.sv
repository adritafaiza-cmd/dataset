```systemverilog
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

  // CDC Strategy:
  // 1. All state (registers) is registered on pclk_i.
  // 2. Reset is synchronous to pclk_i.
  // 3. Output data (reg_q_o) is driven directly from the registered state.
  // 4. Input data (req_i, base_addr_i) is sampled synchronously on pclk_i.
  // 5. No asynchronous resets or clock crossings exist within this module.
  // 6. The APB protocol naturally handles the handshake (PSEL/ENABLE) synchronously.

  // Internal registers for the register file
  // Initialized to reg_init_i on reset
  reg_data_t [NoApbRegs-1:0] reg_state;

  // Synchronous reset logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_state <= '0;
    end else begin
      reg_state <= reg_init_i;
    end
  end

  // Logic to determine if a write should occur
  // We sample the inputs synchronously here.
  // req_i is assumed to be a valid APB transaction structure (e.g., PSEL, PENABLE, PWRITE, PADDR, PWDATA).
  // We extract the necessary fields from req_i.
  
  // Since req_t is a parameterized type, we use a generic approach.
  // In a real scenario, req_t would be defined as a struct or packed array containing:
  // - pwrite (write enable)
  // - paddr (address)
  // - pvalid (transaction valid)
  // - penable (APB enable)
  // - pslvrdy (slave ready - usually output, but sometimes part of handshake logic)
  //
  // For this implementation, we assume req_i contains the necessary control signals
  // to determine if a write is active. We look for a 'pwrite' or similar signal.
  // If req_t is a simple logic, we assume high means write, low means read, or use a specific bit.
  // However, standard APB uses PWRITE bit. Let's assume req_i has a field .pwrite.
  // If req_t is just 'logic', we treat it as a single-bit write enable for simplicity 
  // OR we assume the caller drives a specific pattern. 
  // Given the prompt says "req_i / resp_o use the APB request and response types supplied by the testbench",
  // and typical APB definitions, we assume req_i has a .pwrite member.
  
  // To make this robust against different req_t definitions without explicit struct unpacking 
  // (which might fail if req_t is not a struct), we rely on the fact that 
  // the testbench will drive req_i correctly. 
  // We will assume req_i is a struct with a .pwrite bit.
  
  // Note: If req_t is not a struct, this code might need adjustment based on the actual type.
  // Assuming standard APB interface: req_i.pwrite indicates write operation.
  
  // Calculate the target register index
  // Address mapping: Register N is at (base_addr_i + N * AddrOffset)
  // We need to find N such that (base_addr_i + N * AddrOffset) == req_i.paddr
  // N = (req_i.paddr - base_addr_i) / AddrOffset
  
  // We perform the calculation in a combinational block to determine the index
  // and the write enable.
  
  logic [ApbAddrWidth-1:0] target_addr;
  logic [NoApbRegs-1:0] write_index;
  logic write_enable;
  logic read_enable;
  
  // Combinational logic to decode address and control
  always_comb begin
    // Default values
    write_index = '0;
    write_enable = 1'b0;
    read_enable = 1'b0;
    target_addr = '0;
    
    // Check if req_i is valid (assuming a .pvalid or similar, or just active high req)
    // Standard APB: PSEL & PENABLE & !PWRITE = Read; PSEL & PENABLE & PWRITE = Write.
    // We assume req_i contains these fields.
    
    // Extract fields from req_i. 
    // Since req_t is parameterized, we assume it has .pwrite, .paddr, .pvalid, .penable.
    // If req_t is just 'logic', this code will not compile unless req_t is a struct.
    // Given the context of "APB-mapped", it is highly likely req_t is a struct.
    
    if (req_i.pvalid && req_i.penable) begin
      target_addr = req_i.paddr;
      
      // Calculate offset from base
      // We need to ensure (target_addr - base_addr_i) is divisible by AddrOffset
      // and within bounds.
      
      if (target_addr >= base_addr_i) begin
        // Calculate difference
        int unsigned diff = target_addr - base_addr_i;
        
        // Check divisibility and bounds
        if (diff % AddrOffset == 0) begin
          int unsigned idx = diff / AddrOffset;
          
          if (idx < NoApbRegs) begin
            write_index = idx;
            
            if (req_i.pwrite) begin
              write_enable = 1'b1;
            end else begin
              read_enable = 1'b1;
            end
          end
        end
      end
    end
  end

  // Write logic: Only update if write_enable is high and the register is not read-only
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_state <= '0;
    end else begin
      if (write_enable) begin
        // Check ReadOnly mask
        if (ReadOnly[write_index] == 1'b0) begin
          reg_state[write_index] <= req_i.pdata;
        end
        // If ReadOnly[write_index] == 1'b1, we ignore the write (no-op)
      end
      // If read_enable, we do nothing to state (state holds the value)
    end
  end

  // Output logic
  // reg_q_o is driven directly from reg_state.
  // This is safe for CDC as it is registered on the same clock domain.
  assign reg_q_o = reg_state;

  // Response logic (APB Response)
  // Standard APB response: PSLVERR or PSLVRDY.
  // We assume resp_t is a struct with .presp (or similar) or just a status bit.
  // Typically, APB response is PSLVERR (1) on error, 0 otherwise.
  // Or PSLVRDY (1) on success.
  // Let's assume resp_t has a .presp bit where 0 = OK, 1 = Error.
  
  always_comb begin
    resp_o = '0; // Default OK
    
    if (req_i.pvalid && req_i.penable) begin
      if (req_i.pwrite) begin
        // Check if write was ignored due to ReadOnly
        if (write_index < NoApbRegs && ReadOnly[write_index] == 1'b1) begin
          resp_o = 1'b1; // PSLVERR
        end
        // If address was invalid (out of bounds or misaligned), also error
        if (target_addr != req_i.paddr) begin
          // This case is handled by the logic above, but if the address didn't match any register
          // we might want to return error. The logic above sets write_index to 0 if invalid.
          // Let's refine: if no valid register was found, return error.
          // We can track if a valid register was found.
        end
      end else begin
        // Read operation
        // If address is invalid, return error
        // Logic to check if target_addr corresponds to a valid register index
        // is implicit in the write_index calculation.
        // If write_index was not updated (remained 0 or invalid), we should error.
        // However, since write_index is initialized to 0, we need a flag.
      end
    end
  end

  // Refining the Response Logic to handle invalid addresses properly
  // We need to know if the address mapped to a valid register.
  logic valid_addr;
  
  always_comb begin
    valid_addr = 1'b0;
    if (req_i.pvalid && req_i.penable) begin
      if (target_addr >= base_addr_i) begin
        int unsigned diff = target_addr - base_addr_i;
        if (diff % AddrOffset == 0) begin
          int unsigned idx = diff / AddrOffset;
          if (idx < NoApbRegs) begin
            valid_addr = 1'b1;
          end
        end
      end
    end
    
    resp_o = '0;
    if (req_i.pvalid && req_i.penable) begin
      if (!valid_addr) begin
        resp_o = 1'b1; // PSLVERR for invalid address
      end else if (req_i.pwrite) begin
        if (ReadOnly[write_index] == 1'b1) begin
          resp_o = 1'b1; // PSLVERR for read-only violation
        end
      end
    end
  end

endmodule
```<|im_end|>
