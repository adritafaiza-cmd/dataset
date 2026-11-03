module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  reg [WIDTH-1:0] src_reg, dst_reg;
  reg src_valid_reg, src_ready_reg, dst_valid_reg, dst_ready_reg;
  reg src_reset, dst_reset;
  reg [1:0] src_phase, dst_phase;
  reg src_valid_staged, dst_valid_staged;
  reg [WIDTH-1:0] src_data_staged, dst_data_staged;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reg <= (SEND_RESET_MSG) ? RESET_MSG : {WIDTH{1'b0}};
      src_valid_reg <= SEND_RESET_MSG;
      src_ready_reg <= 1'b1;
      src_phase <= 2'b00;
      src_valid_staged <= 1'b0;
      src_data_staged <= {WIDTH{1'b0}};
      src_reset <= 1'b1;
    end else begin
      src_reset <= 1'b0;
      if (src_valid_i && src_ready_o) begin
        src_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else if (src_phase == 2'b11 && src_valid_staged) begin
        src_valid_reg <= 1'b0;
      end

      // Phase counter for source domain
      if (src_valid_reg && src_ready_reg) begin
        src_phase <= src_phase + 1'b1;
      end else if (src_phase == 2'b11) begin
        src_phase <= 2'b00;
      end

      // Staging valid and data for crossing
      if (src_phase == 2'b10) begin
        src_valid_staged <= src_valid_reg;
        src_data_staged <= src_reg;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reg <= (SEND_RESET_MSG) ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_reg <= SEND_RESET_MSG;
      dst_ready_reg <= 1'b1;
      dst_phase <= 2'b00;
      dst_valid_staged <= 1'b0;
      dst_data_staged <= {WIDTH{1'b0}};
      dst_reset <= 1'b1;
    end else begin
      dst_reset <= 1'b0;
      if (dst_valid_i && dst_ready_o) begin
        dst_reg <= dst_data_i;
        dst_valid_reg <= 1'b1;
      end else if (dst_phase == 2'b11 && dst_valid_staged) begin
        dst_valid_reg <= 1'b0;
      end

      // Phase counter for destination domain
      if (dst_valid_reg && dst_ready_reg) begin
        dst_phase <= dst_phase + 1'b1;
      end else if (dst_phase == 2'b11) begin
        dst_phase <= 2'b00;
      end

      // Staging valid and data for crossing
      if (dst_phase == 2'b10) begin
        dst_valid_staged <= dst_valid_reg;
        dst_data_staged <= dst_reg;
      end
    end
  end

  // Cross-domain handshake
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else begin
      if (DECOUPLED) begin
        src_ready_o <= (src_phase == 2'b00) || (src_phase == 2'b10 && !src_valid_staged);
      end else begin
        src_ready_o <= (src_phase == 2'b00);
      end
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= (SEND_RESET_MSG) ? RESET_MSG : {WIDTH{1'b0}};
    end else begin
      if (dst_phase == 2'b10) begin
        dst_valid_o <= dst_valid_staged;
        dst_data_o <= dst_data_staged;
      end
    end
  end

endmodule
