module cdc_2phase #(
  parameter WIDTH = 1
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

  // Source domain: capture data and generate request pulse
  reg [WIDTH-1:0] src_data_reg;
  reg src_req_pulse;
  wire src_accept = src_valid_i & src_ready_o;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_req_pulse <= 1'b0;
    end else begin
      if (src_accept) begin
        src_data_reg <= src_data_i;
        src_req_pulse <= 1'b1;
      end else begin
        src_req_pulse <= 1'b0;
      end
    end
  end

  // Synchronize request pulse to destination domain
  reg [2:0] req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync <= 3'b000;
    end else begin
      req_sync <= {req_sync[1:0], src_req_pulse};
    end
  end

  // Detect rising edge of synchronized request in destination domain
  wire req_edge = req_sync[1] & ~req_sync[0];

  // Destination domain: hold data and valid
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      if (req_edge) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end else if (dst_valid_reg & dst_ready_i) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  // Synchronize destination valid back to source domain
  reg [2:0] valid_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      valid_sync <= 3'b000;
    end else begin
      valid_sync <= {valid_sync[1:0], dst_valid_reg};
    end
  end

  // Source ready: low when destination has an outstanding item
  assign src_ready_o = ~valid_sync[2];

  // Destination outputs
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
