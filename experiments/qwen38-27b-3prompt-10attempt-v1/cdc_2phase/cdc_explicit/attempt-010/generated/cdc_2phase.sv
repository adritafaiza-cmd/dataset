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

  // Source domain state
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain state
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // Synchronizers for dst_valid -> src domain
  reg [1:0] dst_valid_sync;

  // Synchronizers for src_valid -> dst domain
  reg [1:0] src_valid_sync;

  // Synchronizers for src_data -> dst domain (only valid when src_valid_sync[1] is high)
  reg [WIDTH-1:0] src_data_sync;

  // Synchronizers for dst_ready -> src domain
  reg [1:0] dst_ready_sync;

  // Synchronizers for src_ready -> dst domain
  reg [1:0] src_ready_sync;

  // Compute src_ready: can accept if no outstanding item in src domain
  // and no outstanding item in dst domain (dst_valid_sync[1] is low)
  wire src_ready = !src_valid_reg && !dst_valid_sync[1];

  assign src_ready_o = src_ready;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg  <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && src_ready) begin
        src_valid_reg <= 1'b1;
        src_data_reg  <= src_data_i;
      end else if (dst_valid_sync[1]) begin
        // Destination has consumed the item, clear src valid
        src_valid_reg <= 1'b0;
      end
    end
  end

  // Synchronize src_valid to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_reg};
    end
  end

  // Synchronize src_data to dst domain
  // Data is only stable when src_valid_reg is high, so we can safely synchronize
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= {WIDTH{1'b0}};
    end else begin
      src_data_sync <= src_data_reg;
    end
  end

  // Synchronize dst_valid to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_sync <= 2'b00;
    end else begin
      dst_valid_sync <= {dst_valid_sync[0], dst_valid_reg};
    end
  end

  // Synchronize dst_ready to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Synchronize src_ready to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready};
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg  <= {WIDTH{1'b0}};
    end else begin
      if (!dst_valid_reg && src_valid_sync[1]) begin
        // Accept new item from source
        dst_valid_reg <= 1'b1;
        dst_data_reg  <= src_data_sync;
      end else if (dst_valid_reg && dst_ready_i) begin
        // Item consumed, clear valid
        dst_valid_reg <= 1'b0;
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o  = dst_data_reg;

endmodule
