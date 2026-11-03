module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,
  parameter int unsigned        ApbAddrWidth = 32'd16,
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

  logic [NoApbRegs*RegDataWidth-1:0] reg_data;
  logic [NoApbRegs-1:0]            write_enable;
  reg_data_t                       read_data;
  reg_data_t                       write_data;
  logic [ApbDataWidth/8-1:0]       byte_strobe;
  logic [NoApbRegs-1:0]            addr_match;
  logic [$clog2(NoApbRegs)-1:0]    selected_reg;
  logic                            pending_write;

  // Decode APB address to determine which register is being accessed
  always_comb begin
    addr_match = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      addr_match[i] = (base_addr_i[ApbAddrWidth-1:2] == i[NoApbRegs-1:0]) & req_i;
    end
  end

  // Determine the selected register
  always_comb begin
    selected_reg = 0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (addr_match[i]) selected_reg = i[$clog2(NoApbRegs)-1:0];
    end
  end

  // Generate write enable signals
  always_comb begin
    write_enable = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      write_enable[i] = addr_match[i] & ~ReadOnly[i] & pending_write;
    end
  end

  // Register data memory
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_data <= '0;
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) reg_data[i*RegDataWidth+:RegDataWidth] <= reg_init_i[i];
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (write_enable[i]) begin
          for (int j = 0; j < ApbDataWidth/8; j++) begin
            if (byte_strobe[j]) begin
              reg_data[i*RegDataWidth+j*8+:8] <= write_data[j*8+:8];
            end
          end
        end
      end
    end
  end

  // Output the selected register data
  always_comb begin
    read_data = reg_data[selected_reg*RegDataWidth+:RegDataWidth];
  end

  // Generate response
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o <= 0;
      pending_write <= 0;
    end else begin
      if (req_i) begin
        resp_o <= 1;
        pending_write <= 1;
      end else begin
        resp_o <= 0;
        pending_write <= 0;
      end
    end
  end

  // Assign write data and byte strobes
  always_comb begin
    write_data = req_i ? req_i.prdata : '0;
    byte_strobe = req_i ? req_i.pstrb : '0;
  end

  // Output the register file state
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = reg_data[i*RegDataWidth+:RegDataWidth];
    end
  end

endmodule
