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

  // Extract fields from APB request
  // Assuming standard APB3/4 structure:
  // req_i.psel, req_i.penable, req_i.pwrite, req_i.paddr, req_i.pwdata, req_i.pstrb
  // We'll use member access assuming the type has these fields.

  // Determine if this is a valid APB write or read
  wire apb_sel     = req_i.psel;
  wire apb_enable  = req_i.penable;
  wire apb_write   = req_i.pwrite;
  wire [ApbAddrWidth-1:0] apb_addr = req_i.paddr;
  wire [ApbDataWidth-1:0] apb_wdata = req_i.pwdata;
  wire [ApbDataWidth/8-1:0] apb_strb = req_i.pstrb;

  // Calculate register index from address
  // Address offset from base
  wire [ApbAddrWidth-1:0] addr_offset = apb_addr - base_addr_i;
  
  // Convert byte offset to register index
  // AddrOffset is in bytes, so divide by AddrOffset
  // We need to handle the division carefully
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset / AddrOffset;
  
  // Check if the address is aligned and within range
  wire [ApbAddrWidth-1:0] addr_remainder = addr_offset % AddrOffset;
  wire addr_aligned = (addr_remainder == '0);
  wire addr_in_range = (reg_index_raw < NoApbRegs);
  wire addr_valid = addr_aligned && addr_in_range;

  // Register index as integer
  wire [31:0] reg_idx = addr_valid ? reg_index_raw[31:0] : 32'd0;

  // Write enable: APB write phase (PSEL & PENABLE & PWRITE) and valid address
  wire write_en = apb_sel & apb_enable & apb_write & addr_valid;

  // Read enable: APB read phase (PSEL & PENABLE & !PWRITE) and valid address
  wire read_en = apb_sel & apb_enable & ~apb_write & addr_valid;

  // Response: OKAY for valid accesses, ERROR for invalid
  // In APB, PREADY is typically tied high, and presp indicates status
  // Assuming resp_o has a field like 'presp' or is a simple status
  // We'll set resp_o to indicate OKAY (0) for valid, ERROR (1) for invalid
  // But since resp_t is a type, we need to assign it appropriately.
  // Let's assume resp_o can be assigned a value that represents OKAY/ERROR.
  // For simplicity, we'll create a default response and modify it.

  // Default response: OKAY
  resp_t resp_default;
  // We need to initialize resp_default. Since we don't know the exact structure,
  // we'll assume it has a field that can be set. Let's use a simple approach:
  // If resp_t is a struct with a 'presp' field, we set it to 0 for OKAY.
  // For now, we'll just assign a zero value and let the testbench define the type.
  // Actually, we should construct the response properly.
  
  // Let's assume resp_t has a field 'presp' (1 bit) where 0=OKAY, 1=ERROR
  // We'll create the response based on address validity
  resp_t resp_val;
  // Initialize resp_val to all zeros (OKAY)
  resp_val = '0;
  
  // If address is invalid, set error
  if (!addr_valid && (apb_sel & apb_enable)) begin
    // Set error flag - assuming resp_val has a 'presp' field
    // This is a bit tricky without knowing the exact type structure.
    // We'll use a cast or direct assignment if possible.
    // For now, let's assume we can set a field.
    // Since we can't easily modify struct fields without knowing the structure,
    // let's use a different approach: create a helper function or use direct assignment.
    
    // Actually, in SystemVerilog, we can assign to struct members if we know them.
    // Let's assume resp_t has a member 'presp'.
    // If that's not the case, this will fail. But the problem says "use the APB 
    // request and response types supplied by the testbench", so we should use 
    // standard APB field names.
    
    // Let's try to set resp_val.presp = 1 for error
    // But we need to be careful. Let's just assign the whole struct.
    // For OKAY: resp_val = '0 (assuming presp=0 means OKAY)
    // For ERROR: we need to set presp=1
  end

  // Let's use a simpler approach: 
  // Create the response based on whether the access is valid
  // We'll use a case or conditional assignment
  
  // For now, let's assume resp_t is a struct with at least a 'presp' field
  // and we can assign to it.
  
  // Initialize response to OKAY
  resp_val = '0;
  
  // If invalid address during an active APB transfer, set ERROR
  if ((apb_sel & apb_enable) && !addr_valid) begin
    // Set error - we'll assume we can modify the presp field
    // This is a limitation without knowing the exact type
    // Let's use a workaround: create a localparam or use direct bit manipulation
    // Actually, let's just assume the testbench defines resp_t with a 'presp' field
    // and we can assign to it.
    
    // For now, let's just leave it as OKAY for simplicity, or use a cast
    // The problem states to use the types supplied, so we should be able to 
    // assign to fields. Let's assume resp_val.presp exists.
    
    // Since we can't be sure, let's use a different approach:
    // We'll create the response in a way that works with common APB types.
    // If resp_t is a simple logic, then 0=OKAY, 1=ERROR
    // If resp_t is a struct, we need to set the appropriate field.
    
    // Let's just assign 1 to the whole thing if it's a simple type, 
    // but that might not work for structs.
    
    // For now, let's assume resp_t has a 'presp' field and set it.
    // This is a best-effort approach.
  end

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;

  // Initialize registers on reset
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      // Handle writes
      if (write_en) begin
        // Check if register is read-only
        if (!ReadOnly[reg_idx]) begin
          // Perform write with byte strobes
          // apb_wdata is ApbDataWidth bits, reg_q[reg_idx] is RegDataWidth bits
          // We need to handle the case where ApbDataWidth != RegDataWidth
          // For simplicity, assume ApbDataWidth >= RegDataWidth or they are equal
          // If ApbDataWidth > RegDataWidth, we take the lower RegDataWidth bits
          // If ApbDataWidth < RegDataWidth, we only update the lower ApbDataWidth bits
          
          // Let's handle byte-level writes using pstrb
          // apb_strb has ApbDataWidth/8 bits
          // reg_q[reg_idx] has RegDataWidth bits = RegDataWidth/8 bytes
          
          // For each byte in the register, check if the corresponding strobe is set
          // and if the byte is within the data width
          for (int b = 0; b < RegDataWidth/8; b++) begin
            // Check if this byte is within the APB data width
            if (b < ApbDataWidth/8) begin
              // Check if the strobe for this byte is set
              if (apb_strb[b]) begin
                // Write the byte
                reg_q[reg_idx][b*8 +: 8] <= apb_wdata[b*8 +: 8];
              end
            end
          end
        end
      end
    end
  end

  // Drive output
  assign reg_q_o = reg_q;

  // Response output
  // We need to properly set resp_o
  // Let's use a combinational block to determine the response
  always_comb begin
    // Default: OKAY
    resp_o = '0;
    
    // If there's an active APB transfer with invalid address, set ERROR
    if ((apb_sel & apb_enable) && !addr_valid) begin
      // Set error response
      // Assuming resp_o has a 'presp' field
      // We'll try to set it
      // For now, let's just assign a non-zero value
      // This is a limitation without knowing the exact type structure
      resp_o = '1; // This might not be correct for all types
    end
  end

endmodule
