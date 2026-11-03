module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,  // Example value, adjust as needed
  parameter int unsigned        ApbAddrWidth = 32'd16, // Example value, adjust as needed
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd32,
  parameter int unsigned        RegDataWidth = 32'd32,
  parameter bit [NoApbRegs-1:0] ReadOnly     = 32'h0,
  parameter type                req_t        = logic,
  parameter type                resp_t       = logic,
  parameter type                apb_addr_t   = logic[ApbAddrWidth-1:0],
  parameter type                reg_data_t   = logic[RegDataWidth-1:0]
) (
  input  logic                      pclk_i,
  input  logic                      preset_ni,
  input  req_t                      req_i,
  output resp_t                     resp_o,
  input  apb_addr_t                 base_addr_i,
  input  reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);

  // Internal signals
  reg_data_t [NoApbRegs-1:0] registers;
  logic [NoApbRegs-1:0]      decoded_addr;
  reg_data_t                 write_data;
  logic [RegDataWidth/8-1:0] write_strobe;
  reg_data_t                 read_data;
  logic                      pending_write;
  logic [NoApbRegs-1:0]      pending_write_addr;
  reg_data_t                 pending_write_data;
  logic [RegDataWidth/8-1:0] pending_write_strobe;

  // Decode the address
  always_comb begin
    decoded_addr = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (req_i.paddr >= base_addr_i + i * AddrOffset &&
          req_i.paddr < base_addr_i + (i + 1) * AddrOffset) begin
        decoded_addr[i] = 1'b1;
      end
    end
  end

  // Assign read data
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (decoded_addr[i]) begin
        read_data = ReadOnly[i] ? reg_init_i[i] : registers[i];
      end
    end
  end

  // Process APB request
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o <= 0;
      pending_write <= 0;
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          registers[i] <= reg_init_i[i];
        end else begin
          registers[i] <= 0;
        end
      end
    end else begin
      if (req_i.psel && req_i.penable) begin
        resp_o <= 1;
        for (int i = 0; i < NoApbRegs; i++) begin
          if (decoded_addr[i] && !ReadOnly[i] && pending_write) begin
            for (int j = 0; j < RegDataWidth/8; j++) begin
              if (pending_write_strobe[j]) begin
                registers[i][j*8 +: 8] <= pending_write_data[j*8 +: 8];
              end
            end
          end
        end
        pending_write <= 0;
      end else if (req_i.psel && !req_i.penable) begin
        write_data <= req_i.pwdata;
        write_strobe <= req_i.pstrb;
        pending_write <= 1;
        pending_write_addr <= decoded_addr;
        pending_write_data <= req_i.pwdata;
        pending_write_strobe <= req_i.pstrb;
      end
    end
  end

  // Output current register values
  always_comb begin
    reg_q_o = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = ReadOnly[i] ? reg_init_i[i] : registers[i];
    end
  end

endmodule
