module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  logic [WIDTH-1:0] src_data_out;
  logic src_valid_out;
  logic src_clear_out;
  logic dst_data_out;
  logic dst_valid_out;
  logic dst_clear_out;

  // Sync registers for source domain
  sync_reg #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) src_sync (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .data_in(src_data_i),
    .valid_in(src_valid_i),
    .clear_in(src_clear_i),
    .data_out(src_data_out),
    .valid_out(src_valid_out),
    .clear_out(src_clear_out)
  );

  // Sync registers for destination domain
  sync_reg #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) dst_sync (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .data_in(src_data_out),
    .valid_in(src_valid_out),
    .clear_in(src_clear_out),
    .data_out(dst_data_out),
    .valid_out(dst_valid_out),
    .clear_out(dst_clear_out)
  );

  // Handshake logic for source domain
  handshake src_handshake (
    .valid_in(src_valid_out),
    .ready_out(src_ready_o)
  );

  // Handshake logic for destination domain
  handshake dst_handshake (
    .valid_in(dst_valid_o),
    .ready_out(dst_ready_i)
  );

  // Clear logic for source domain
  clear_logic src_clear_logic (
    .clear_in(src_clear_i),
    .clear_out(src_clear_out)
  );

  // Clear logic for destination domain
  clear_logic dst_clear_logic (
    .clear_in(dst_clear_i),
    .clear_out(dst_clear_out)
  );

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_out;
  assign dst_clear_pending_o = dst_clear_out;

endmodule

// Sync register module
module sync_reg #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk,
  input  rst_n,
  input  [WIDTH-1:0] data_in,
  input  valid_in,
  input  clear_in,
  output [WIDTH-1:0] data_out,
  output valid_out,
  output clear_out
);

  // Internal signals
  logic [WIDTH-1:0] shift_reg [SYNC_STAGES];
  logic [SYNC_STAGES-1:0] valid_reg;
  logic [SYNC_STAGES-1:0] clear_reg;

  // Shift register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= '{default: 0};
      valid_reg <= '{default: 0};
      clear_reg <= '{default: 0};
    end else if (clear_in) begin
      shift_reg <= '{default: 0};
      valid_reg <= '{default: 0};
      clear_reg <= '{default: 1};
    end else begin
      shift_reg[0] <= data_in;
      valid_reg[0] <= valid_in;
      clear_reg[0] <= 0;
      for (int i = 0; i < SYNC_STAGES-1; i++) begin
        shift_reg[i+1] <= shift_reg[i];
        valid_reg[i+1] <= valid_reg[i];
        clear_reg[i+1] <= clear_reg[i];
      end
    end
  end

  // Outputs
  assign data_out = shift_reg[SYNC_STAGES-1];
  assign valid_out = valid_reg[SYNC_STAGES-1];
  assign clear_out = clear_reg[SYNC_STAGES-1];

endmodule

// Handshake module
module handshake (
  input  valid_in,
  output ready_out
);

  // Internal signals
  logic ready_in;
  logic handshake;

  // Handshake logic
  assign ready_out = handshake;
  assign handshake = valid_in & ready_in;

  // Ready input (to be driven by the destination domain)
  // This is a placeholder and should be connected to the destination domain's ready signal
  assign ready_in = 1'b1; // Placeholder

endmodule

// Clear logic module
module clear_logic (
  input  clear_in,
  output clear_out
);

  // Internal signals
  logic clear_reg;

  // Clear logic
  always_ff @(posedge clear_in or negedge clear_out) begin
    if (!clear_out) begin
      clear_reg <= 1'b0;
    end else begin
      clear_reg <= 1'b1;
    end
  end

  // Clear output
  assign clear_out = clear_reg;

endmodule
