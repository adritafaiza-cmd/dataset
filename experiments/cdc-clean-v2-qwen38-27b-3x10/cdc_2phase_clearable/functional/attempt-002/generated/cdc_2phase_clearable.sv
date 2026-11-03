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
  wire src_req;
  wire src_ack;
  wire dst_req;
  wire dst_ack;

  // Source domain: request generation
  reg src_req_reg;
  reg src_clear_pending_reg;
  reg src_isolated_reg;

  // Destination domain: acknowledge generation
  reg dst_ack_reg;
  reg dst_clear_pending_reg;
  reg dst_isolated_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Synchronizers
  wire [SYNC_STAGES-1:0] src_req_sync;
  wire [SYNC_STAGES-1:0] src_ack_sync;
  wire [SYNC_STAGES-1:0] dst_req_sync;
  wire [SYNC_STAGES-1:0] dst_ack_sync;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_isolated_reg <= 1'b0;
    end else begin
      if (src_clear_i) begin
        // Initiate clear: isolate and drop in-flight
        src_isolated_reg <= 1'b1;
        src_clear_pending_reg <= 1'b1;
        src_req_reg <= 1'b0;
      end else if (src_isolated_reg) begin
        // Wait for ack to return to 0 (clear complete)
        if (!src_ack_sync[SYNC_STAGES-1]) begin
          src_isolated_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
      end else begin
        // Normal operation
        if (src_valid_i && !src_req_reg && dst_ready_i) begin
          src_req_reg <= 1'b1;
        end else if (src_req_reg && src_ack_sync[SYNC_STAGES-1]) begin
          src_req_reg <= 1'b0;
        end
      end
    end
  end

  assign src_req = src_req_reg;
  assign src_ready_o = !src_req_reg && !src_isolated_reg && !src_clear_pending_reg;
  assign src_clear_pending_o = src_clear_pending_reg;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_isolated_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        // Initiate clear: isolate and drop in-flight
        dst_isolated_reg <= 1'b1;
        dst_clear_pending_reg <= 1'b1;
        dst_ack_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
      end else if (dst_isolated_reg) begin
        // Wait for req to return to 0 (clear complete)
        if (!dst_req_sync[SYNC_STAGES-1]) begin
          dst_isolated_reg <= 1'b0;
          dst_clear_pending_reg <= 1'b0;
        end
      end else begin
        // Normal operation
        if (dst_req_sync[SYNC_STAGES-1] && !dst_ack_reg) begin
          // Capture data on request edge
          dst_data_reg <= dst_data_reg; // Data is captured via separate path
          dst_ack_reg <= 1'b1;
          dst_valid_reg <= 1'b1;
        end else if (dst_ack_reg && dst_ready_i) begin
          dst_ack_reg <= 1'b0;
          dst_valid_reg <= 1'b0;
        end
      end
    end
  end

  assign dst_ack = dst_ack_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

  // Data path: source data must be stable when request is asserted
  // We need to capture source data when request is asserted and hold it until ack
  reg [WIDTH-1:0] src_data_hold;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_hold <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && !src_req_reg && dst_ready_i) begin
        src_data_hold <= src_data_i;
      end
    end
  end

  // Synchronizers for request (src to dst)
  genvar i;
  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_src_req_sync
      if (i == 0) begin
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            src_req_sync[0] <= 1'b0;
          else
            src_req_sync[0] <= src_req;
        end
      end else begin
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            src_req_sync[i] <= 1'b0;
          else
            src_req_sync[i] <= src_req_sync[i-1];
        end
      end
    end
  endgenerate

  // Synchronizers for ack (dst to src)
  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_src_ack_sync
      if (i == 0) begin
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            src_ack_sync[0] <= 1'b0;
          else
            src_ack_sync[0] <= dst_ack;
        end
      end else begin
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            src_ack_sync[i] <= 1'b0;
          else
            src_ack_sync[i] <= src_ack_sync[i-1];
        end
      end
    end
  endgenerate

  // Synchronizers for request (dst to src) - for clear completion detection
  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_dst_req_sync
      if (i == 0) begin
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            dst_req_sync[0] <= 1'b0;
          else
            dst_req_sync[0] <= src_req;
        end
      end else begin
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            dst_req_sync[i] <= 1'b0;
          else
            dst_req_sync[i] <= dst_req_sync[i-1];
        end
      end
    end
  endgenerate

  // Synchronizers for ack (src to dst) - not needed for this design
  // But we need to sync dst_ack to src domain, which is src_ack_sync above

  // Data crossing: we need to safely transfer data from src to dst
  // Use a simple approach: hold data in src domain, and use a gray-code-like
  // or simply rely on the handshake to ensure data is stable
  // For simplicity, we'll use a multi-bit synchronizer with handshake protection
  
  // Actually, for a two-phase handshake, the data is stable while req is high.
  // We can use a simple multi-bit synchronizer since the data is stable.
  
  // Let's use a different approach: capture data in dst domain when req rises
  // But we need the data to be stable. Since req is high while data is stable,
  // we can sample the data in dst domain when we see req go high.
  
  // For multi-bit data, we need to ensure metastability safety.
  // One approach: use a FIFO-like structure or ensure data changes only when req is low.
  
  // Given the constraints, let's use a simple approach where we assume
  // the data is stable during the request phase and use a multi-bit sync.
  
  // Actually, the safest approach for multi-bit data in a two-phase handshake
  // is to ensure that the data only changes when the request is deasserted.
  // Since we hold the data in src_data_hold, it's stable while req is high.
  
  // Let's add a data synchronizer
  wire [WIDTH-1:0] dst_data_sync;
  
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_data_sync
      if (i == 0) begin
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            dst_data_sync[i] <= 1'b0;
          else
            dst_data_sync[i] <= src_data_hold[i];
        end
      end else begin
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            dst_data_sync[i] <= 1'b0;
          else
            dst_data_sync[i] <= src_data_hold[i];
        end
      end
    end
  endgenerate

  // Update dst_data_reg when we capture the request
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      if (dst_req_sync[SYNC_STAGES-1] && !dst_ack_reg) begin
        dst_data_reg <= dst_data_sync;
      end
    end
  end

endmodule
