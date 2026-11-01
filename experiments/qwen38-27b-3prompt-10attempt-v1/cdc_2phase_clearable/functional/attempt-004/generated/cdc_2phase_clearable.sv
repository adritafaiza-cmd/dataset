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
  wire src_clear_active;
  wire dst_clear_active;
  wire src_clear_req_synced;
  wire dst_clear_req_synced;
  wire src_clear_ack_synced;
  wire dst_clear_ack_synced;

  // Source domain clear logic
  reg src_clear_pending_r;
  reg src_clear_ack_r;
  reg src_clear_ack_sync_r [SYNC_STAGES-1:0];

  // Destination domain clear logic
  reg dst_clear_pending_r;
  reg dst_clear_ack_r;
  reg dst_clear_ack_sync_r [SYNC_STAGES-1:0];

  // Source domain: clear request sync to destination
  reg src_clear_req_sync_r [SYNC_STAGES-1:0];

  // Destination domain: clear request sync to source
  reg dst_clear_req_sync_r [SYNC_STAGES-1:0];

  // Source domain: clear ack sync to destination
  reg src_clear_ack_sync_r2 [SYNC_STAGES-1:0];

  // Destination domain: clear ack sync to source
  reg dst_clear_ack_sync_r2 [SYNC_STAGES-1:0];

  // Source domain: data and valid
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  reg src_ready_r;

  // Destination domain: data and valid
  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;

  // Source domain: handshake signals
  reg src_req_r;
  reg src_ack_r;

  // Destination domain: handshake signals
  reg dst_req_r;
  reg dst_ack_r;

  // Sync src_req to destination
  reg src_req_sync_r [SYNC_STAGES-1:0];

  // Sync dst_ack to source
  reg dst_ack_sync_r [SYNC_STAGES-1:0];

  // Sync dst_req to source
  reg dst_req_sync_r [SYNC_STAGES-1:0];

  // Sync src_ack to destination
  reg src_ack_sync_r [SYNC_STAGES-1:0];

  // Source domain: clear active
  assign src_clear_active = src_clear_i || (CLEAR_ON_ASYNC_RESET && !src_rst_ni);

  // Destination domain: clear active
  assign dst_clear_active = dst_clear_i || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni);

  // Source domain: clear pending
  assign src_clear_pending_o = src_clear_pending_r;

  // Destination domain: clear pending
  assign dst_clear_pending_o = dst_clear_pending_r;

  // Source domain: ready
  assign src_ready_o = src_ready_r;

  // Destination domain: data and valid
  assign dst_data_o = dst_data_r;
  assign dst_valid_o = dst_valid_r;

  // Source domain: clear request sync
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req_sync_r <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_req_sync_r[0] <= src_clear_active;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        src_clear_req_sync_r[i] <= src_clear_req_sync_r[i-1];
      end
    end
  end

  // Destination domain: clear request sync
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_req_sync_r <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_req_sync_r[0] <= dst_clear_active;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        dst_clear_req_sync_r[i] <= dst_clear_req_sync_r[i-1];
      end
    end
  end

  // Source domain: clear ack sync to destination
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_ack_sync_r2 <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_ack_sync_r2[0] <= src_clear_ack_r;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        src_clear_ack_sync_r2[i] <= src_clear_ack_sync_r2[i-1];
      end
    end
  end

  // Destination domain: clear ack sync to source
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_ack_sync_r2 <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_ack_sync_r2[0] <= dst_clear_ack_r;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        dst_clear_ack_sync_r2[i] <= dst_clear_ack_sync_r2[i-1];
      end
    end
  end

  // Source domain: clear pending and ack
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_r <= 1'b0;
      src_clear_ack_r <= 1'b0;
    end else begin
      if (src_clear_active) begin
        src_clear_pending_r <= 1'b1;
        src_clear_ack_r <= 1'b0;
      end else if (src_clear_pending_r) begin
        if (dst_clear_ack_synced) begin
          src_clear_pending_r <= 1'b0;
          src_clear_ack_r <= 1'b1;
        end
      end else begin
        src_clear_ack_r <= 1'b0;
      end
    end
  end

  // Destination domain: clear pending and ack
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_r <= 1'b0;
      dst_clear_ack_r <= 1'b0;
    end else begin
      if (dst_clear_active) begin
        dst_clear_pending_r <= 1'b1;
        dst_clear_ack_r <= 1'b0;
      end else if (dst_clear_pending_r) begin
        if (src_clear_ack_synced) begin
          dst_clear_pending_r <= 1'b0;
          dst_clear_ack_r <= 1'b1;
        end
      end else begin
        dst_clear_ack_r <= 1'b0;
      end
    end
  end

  // Source domain: sync dst_clear_ack to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_ack_sync_r <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_ack_sync_r[0] <= dst_clear_ack_r;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        dst_clear_ack_sync_r[i] <= dst_clear_ack_sync_r[i-1];
      end
    end
  end

  // Destination domain: sync src_clear_ack to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_ack_sync_r <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_ack_sync_r[0] <= src_clear_ack_r;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        src_clear_ack_sync_r[i] <= src_clear_ack_sync_r[i-1];
      end
    end
  end

  assign dst_clear_ack_synced = dst_clear_ack_sync_r[SYNC_STAGES-1];
  assign src_clear_ack_synced = src_clear_ack_sync_r[SYNC_STAGES-1];

  // Source domain: sync dst_ack to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync_r <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ack_sync_r[0] <= dst_ack_r;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        dst_ack_sync_r[i] <= dst_ack_sync_r[i-1];
      end
    end
  end

  // Destination domain: sync src_ack to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ack_sync_r <= {SYNC_STAGES{1'b0}};
    end else begin
      src_ack_sync_r[0] <= src_ack_r;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        src_ack_sync_r[i] <= src_ack_sync_r[i-1];
      end
    end
  end

  // Source domain: sync dst_req to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_req_sync_r <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_req_sync_r[0] <= dst_req_r;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        dst_req_sync_r[i] <= dst_req_sync_r[i-1];
      end
    end
  end

  // Destination domain: sync src_req to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync_r <= {SYNC_STAGES{1'b0}};
    end else begin
      src_req_sync_r[0] <= src_req_r;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        src_req_sync_r[i] <= src_req_sync_r[i-1];
      end
    end
  end

  // Source domain: handshake logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_r <= 1'b0;
      src_ack_r <= 1'b0;
      src_data_r <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_ready_r <= 1'b0;
    end else begin
      if (src_clear_active || src_clear_pending_r) begin
        src_req_r <= 1'b0;
        src_ack_r <= 1'b0;
        src_data_r <= {WIDTH{1'b0}};
        src_valid_r <= 1'b0;
        src_ready_r <= 1'b0;
      end else begin
        // Two-phase handshake
        if (src_req_r) begin
          if (dst_ack_sync_r[SYNC_STAGES-1]) begin
            // Ack received, deassert req
            src_req_r <= 1'b0;
            src_ack_r <= 1'b1;
            src_valid_r <= 1'b0;
            src_ready_r <= 1'b1;
          end
        end else begin
          if (src_ack_r) begin
            if (dst_req_sync_r[SYNC_STAGES-1]) begin
              // Req from dst, deassert ack
              src_ack_r <= 1'b0;
              src_ready_r <= 1'b0;
            end
          end else begin
            // Both req and ack are low, can accept new data
            if (src_valid_i) begin
              src_req_r <= 1'b1;
              src_data_r <= src_data_i;
              src_valid_r <= 1'b1;
              src_ready_r <= 1'b0;
            end else begin
              src_ready_r <= 1'b1;
            end
          end
        end
      end
    end
  end

  // Destination domain: handshake logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_r <= 1'b0;
      dst_ack_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
    end else begin
      if (dst_clear_active || dst_clear_pending_r) begin
        dst_req_r <= 1'b0;
        dst_ack_r <= 1'b0;
        dst_data_r <= {WIDTH{1'b0}};
        dst_valid_r <= 1'b0;
      end else begin
        // Two-phase handshake
        if (dst_req_r) begin
          if (src_ack_sync_r[SYNC_STAGES-1]) begin
            // Ack received, deassert req
            dst_req_r <= 1'b0;
            dst_ack_r <= 1'b1;
            dst_valid_r <= 1'b0;
          end
        end else begin
          if (dst_ack_r) begin
            if (src_req_sync_r[SYNC_STAGES-1]) begin
              // Req from src, deassert ack
              dst_ack_r <= 1'b0;
              dst_valid_r <= 1'b1;
              dst_data_r <= src_data_r;
            end
          end else begin
            // Both req and ack are low
            if (dst_ready_i) begin
              dst_req_r <= 1'b1;
            end
          end
        end
      end
    end
  end

endmodule
