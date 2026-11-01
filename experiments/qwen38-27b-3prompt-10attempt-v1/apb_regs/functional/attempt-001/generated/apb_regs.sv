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

  // Extract APB fields from req_t
  // Assuming standard APB3/4 structure:
  // req_t has fields: psel, penable, pwrite, paddr, pwdata, pstrb, pprot
  // We need to access these fields. Since req_t is a type parameter,
  // we assume it's a struct with these fields.
  
  // For APB, the typical fields are:
  // - psel: select
  // - penable: enable
  // - pwrite: write enable
  // - paddr: address
  // - pwdata: write data
  // - pstrb: byte strobes
  // - pprot: protection type
  
  // We'll assume the struct has these field names.
  
  // Decode address to register index
  // Address offset from base, divided by AddrOffset gives register index
  
  // Calculate relative address
  apb_addr_t rel_addr;
  assign rel_addr = req_i.paddr - base_addr_i;
  
  // Convert to register index
  // AddrOffset is in bytes, so divide by AddrOffset
  // We need to handle the division carefully
  
  // For simplicity, assume AddrOffset is a power of 2 (typically 4)
  // reg_index = rel_addr / AddrOffset
  // If AddrOffset = 4, then reg_index = rel_addr[ApbAddrWidth-1:2]
  
  // Let's compute the register index
  // The number of address bits needed for register index
  localparam int unsigned AddrOffsetLog2 = (AddrOffset == 1) ? 0 :
                                           (AddrOffset == 2) ? 1 :
                                           (AddrOffset == 4) ? 2 :
                                           (AddrOffset == 8) ? 3 :
                                           (AddrOffset == 16) ? 4 :
                                           (AddrOffset == 32) ? 5 :
                                           (AddrOffset == 64) ? 6 :
                                           (AddrOffset == 128) ? 7 :
                                           (AddrOffset == 256) ? 8 :
                                           (AddrOffset == 512) ? 9 :
                                           (AddrOffset == 1024) ? 10 :
                                           (AddrOffset == 2048) ? 11 :
                                           (AddrOffset == 4096) ? 12 :
                                           (AddrOffset == 8192) ? 13 :
                                           (AddrOffset == 16384) ? 14 :
                                           (AddrOffset == 32768) ? 15 :
                                           (AddrOffset == 65536) ? 16 :
                                           (AddrOffset == 131072) ? 17 :
                                           (AddrOffset == 262144) ? 18 :
                                           (AddrOffset == 524288) ? 19 :
                                           (AddrOffset == 1048576) ? 20 :
                                           (AddrOffset == 2097152) ? 21 :
                                           (AddrOffset == 4194304) ? 22 :
                                           (AddrOffset == 8388608) ? 23 :
                                           (AddrOffset == 16777216) ? 24 :
                                           (AddrOffset == 33554432) ? 25 :
                                           (AddrOffset == 67108864) ? 26 :
                                           (AddrOffset == 134217728) ? 27 :
                                           (AddrOffset == 268435456) ? 28 :
                                           (AddrOffset == 536870912) ? 29 :
                                           (AddrOffset == 1073741824) ? 30 :
                                           (AddrOffset == 2147483648) ? 31 : 0;
  
  // Register index from address
  logic [ApbAddrWidth-1:0] reg_index;
  assign reg_index = rel_addr >> AddrOffsetLog2;
  
  // Check if address is valid (within range)
  logic addr_valid;
  assign addr_valid = (reg_index < NoApbRegs);
  
  // APB phase detection
  // Setup phase: psel=1, penable=0
  // Access phase: psel=1, penable=1
  
  logic setup_phase;
  logic access_phase;
  assign setup_phase = req_i.psel && !req_i.penable;
  assign access_phase = req_i.psel && req_i.penable;
  
  // Response
  // In APB, pready is typically high (ready)
  // presp is error response
  // We'll set pready=1 and presp=0 for valid addresses, presp=1 for invalid
  
  // For the response type, we assume it has fields: pready, presp
  // Or it could be a simple status
  
  // Let's assume resp_t has fields: pready, presp
  // If resp_t is just a logic, we'll handle it differently
  
  // Since resp_t is a type parameter, we need to be careful
  // Let's assume it's a struct with pready and presp fields
  
  // For now, let's assume the response is ready when in access phase
  // and the address is valid
  
  // Drive response
  // In APB, the response is valid during the access phase
  // pready should be high to indicate ready
  // presp should be 0 for OK, 1 for error
  
  // We'll drive resp_o based on the phase and address validity
  
  // For simplicity, let's assume resp_t is a struct with pready and presp
  // If it's just a logic, we'll need to adapt
  
  // Let's use a case approach: if resp_t is a struct, we set fields
  // But since we don't know the exact structure, let's assume common APB response
  
  // Actually, looking at the port declaration, resp_t is a type parameter
  // We need to drive it appropriately
  
  // Let's assume resp_t has at least a pready field
  // For APB, pready is typically always 1 (no wait states)
  
  // Let's drive resp_o with pready=1 and presp based on address validity
  
  // Since we can't easily set struct fields without knowing the exact structure,
  // let's assume resp_t is a simple type or has standard APB fields
  
  // For a robust implementation, let's assume resp_t is a struct with:
  // - pready: logic
  // - presp: logic
  
  // We'll create the response
  resp_t resp_val;
  
  // Set pready to 1 (ready)
  // Set presp to 0 for valid, 1 for invalid address
  // But we need to know the field names
  
  // Let's assume the fields are named pready and presp
  // This is a common convention
  
  // For the write operation, we need to handle byte strobes
  // pstrb indicates which bytes are being written
  
  // Write data
  logic [ApbDataWidth-1:0] write_data;
  assign write_data = req_i.pwdata;
  
  // Byte strobes
  logic [ApbDataWidth/8-1:0] byte_strobe;
  assign byte_strobe = req_i.pstrb;
  
  // Register file
  reg_data_t [NoApbRegs-1:0] reg_file;
  
  // Initialize registers
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_file[i] <= reg_init_i[i];
      end
    end else begin
      // Handle writes during access phase
      if (access_phase && req_i.pwrite && addr_valid) begin
        // Apply byte strobes
        for (int b = 0; b < ApbDataWidth/8; b++) begin
          if (byte_strobe[b]) begin
            // Write byte b to the register
            // Only if not read-only
            if (!ReadOnly[reg_index]) begin
              reg_file[reg_index][b*8 +: 8] <= write_data[b*8 +: 8];
            end
          end
        end
      end
    end
  end
  
  // Drive register outputs
  always @(*) begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = reg_file[i];
    end
  end
  
  // Drive response
  // In APB, the response is typically driven during the access phase
  // pready = 1 (no wait states)
  // presp = 0 for OK, 1 for error
  
  // Let's assume resp_t is a struct with pready and presp fields
  // We'll set them accordingly
  
  // For the response, we need to handle the case where resp_t might be
  // a simple logic or a struct
  
  // Let's assume it's a struct with pready and presp
  // If that's not the case, this will need adjustment
  
  // Drive response based on phase
  always @(*) begin
    // Default: not ready
    resp_val.pready = 1'b0;
    resp_val.presp  = 1'b0;
    
    if (access_phase) begin
      resp_val.pready = 1'b1;
      resp_val.presp  = ~addr_valid;
    end
  end
  
  assign resp_o = resp_val;

endmodule
