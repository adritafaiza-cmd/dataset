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

  // Internal signals
  logic [WIDTH-1:0] src_data_ff;
  logic src_valid_ff;
  logic dst_data_sync;
  logic dst_valid_sync;

  // Source FIFO
  logic [WIDTH-1:0] src_fifo_data_out;
  logic src_fifo_valid_out;
  logic src_fifo_ready_in;

  // Destination FIFO
  logic [WIDTH-1:0] dst_fifo_data_in;
  logic dst_fifo_valid_in;
  logic dst_fifo_ready_out;

  // Instantiate source FIFO
  src_ff #(.WIDTH(WIDTH)) src_ff_inst (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .data_in(src_data_i),
    .valid_in(src_valid_i),
    .ready_out(src_ready_o),
    .data_out(src_data_ff),
    .valid_out(src_valid_ff)
  );

  // Instantiate two-phase synchronization
  cdc_sync #(.WIDTH(WIDTH)) cdc_sync_inst (
    .src_clk(src_clk_i),
    .dst_clk(dst_clk_i),
    .src_rst_n(src_rst_ni),
    .dst_rst_n(dst_rst_ni),
    .src_valid(src_valid_ff),
    .src_data(src_data_ff),
    .dst_valid(dst_valid_sync),
    .dst_data(dst_data_sync)
  );

  // Instantiate destination FIFO
  dst_ff #(.WIDTH(WIDTH)) dst_ff_inst (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .data_in(dst_data_sync),
    .valid_in(dst_valid_sync),
    .ready_out(dst_ready_i),
    .data_out(dst_data_o),
    .valid_out(dst_valid_o)
  );

endmodule

// FIFO with valid/ready interface
module src_ff #(
  parameter WIDTH = 1
)(
  input  clk,
  input  rst_n,
  input  [WIDTH-1:0] data_in,
  input  valid_in,
  output ready_out,
  output [WIDTH-1:0] data_out,
  output valid_out
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= 0;
      valid_reg <= 0;
      ready_reg <= 1;
    end else begin
      if (valid_in && ready_reg) begin
        data_reg <= data_in;
        valid_reg <= 1;
      end
      ready_reg <= valid_reg && !valid_out;
    end
  end

  assign data_out = data_reg;
  assign valid_out = valid_reg;
  assign ready_out = ready_reg;

endmodule

// Two-phase synchronization between two clock domains
module cdc_sync #(
  parameter WIDTH = 1
)(
  input  src_clk,
  input  dst_clk,
  input  src_rst_n,
  input  dst_rst_n,
  input  src_valid,
  input  [WIDTH-1:0] src_data,
  output dst_valid,
  output [WIDTH-1:0] dst_data
);

  logic [WIDTH-1:0] sync_reg1;
  logic [WIDTH-1:0] sync_reg2;
  logic sync_valid1;
  logic sync_valid2;

  // First synchronization stage
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      sync_reg1 <= 0;
      sync_valid1 <= 0;
    end else begin
      if (src_valid) begin
        sync_reg1 <= src_data;
        sync_valid1 <= 1;
      end
    end
  end

  // Second synchronization stage
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      sync_reg2 <= 0;
      sync_valid2 <= 0;
    end else begin
      sync_reg2 <= sync_reg1;
      sync_valid2 <= sync_valid1;
    end
  end

  assign dst_valid = sync_valid2;
  assign dst_data = sync_reg2;

endmodule

// FIFO with valid/ready interface
module dst_ff #(
  parameter WIDTH = 1
)(
  input  clk,
  input  rst_n,
  input  [WIDTH-1:0] data_in,
  input  valid_in,
  output ready_out,
  output [WIDTH-1:0] data_out,
  output valid_out
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= 0;
      valid_reg <= 0;
      ready_reg <= 1;
    end else begin
      if (valid_in && ready_reg) begin
        data_reg <= data_in;
        valid_reg <= 1;
      end
      ready_reg <= valid_reg && !valid_out;
    end
  end

  assign data_out = data_reg;
  assign valid_out = valid_reg;
  assign ready_out = ready_reg;

endmodule
