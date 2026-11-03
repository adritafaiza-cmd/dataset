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

  // Source domain state
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ready_reg;
  reg             src_pending;

  // Destination domain state
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_ready_reg;
  reg             dst_pending;

  // Synchronization signals
  // src_to_dst: indicates source has data ready for destination
  reg [1:0] src_to_dst_sync;
  reg       src_to_dst;
  
  // dst_to_src: indicates destination is ready to accept new data
  reg [1:0] dst_to_src_sync;
  reg       dst_to_src;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_pending   <= 1'b0;
      src_to_dst    <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        // Accept data from source
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
        src_to_dst    <= 1'b1;
        
        if (DECOUPLED) begin
          // In decoupled mode, we can accept new data immediately
          // but we need to track that we have pending data
          src_pending <= 1'b1;
          src_ready_reg <= 1'b1; // Keep ready high in decoupled mode
        end else begin
          // In coupled mode, wait for destination to be ready
          src_ready_reg <= 1'b0;
        end
      end else if (dst_to_src && !src_valid_reg) begin
        // Destination is ready and we don't have pending data
        src_ready_reg <= 1'b1;
      end else if (dst_to_src && src_valid_reg) begin
        // Destination is ready and we have pending data
        // This means the previous transfer is complete
        src_valid_reg <= 1'b0;
        src_to_dst    <= 1'b0;
        
        if (DECOUPLED) begin
          src_ready_reg <= 1'b1;
          src_pending   <= 1'b0;
        end else begin
          src_ready_reg <= 1'b1;
        end
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
      dst_pending   <= 1'b0;
      dst_to_src    <= 1'b0;
    end else begin
      if (src_to_dst && !dst_valid_reg) begin
        // Source has data and destination is not currently valid
        dst_data_reg  <= src_to_dst_data;
        dst_valid_reg <= 1'b1;
        dst_to_src    <= 1'b0;
        
        if (DECOUPLED) begin
          dst_pending <= 1'b1;
          dst_ready_reg <= 1'b1;
        end else begin
          dst_ready_reg <= 1'b0;
        end
      end else if (dst_valid_reg && dst_ready_i) begin
        // Destination handshake complete
        dst_valid_reg <= 1'b0;
        dst_to_src    <= 1'b1;
        
        if (DECOUPLED) begin
          dst_ready_reg <= 1'b1;
          dst_pending   <= 1'b0;
        end else begin
          dst_ready_reg <= 1'b1;
        end
      end
    end
  end

  // Synchronizers
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_to_dst_sync <= 2'b00;
    end else begin
      src_to_dst_sync <= {src_to_dst_sync[0], src_to_dst};
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_to_src_sync <= 2'b00;
    end else begin
      dst_to_src_sync <= {dst_to_src_sync[0], dst_to_src};
    end
  end

  // Assign outputs
  assign src_ready_o = src_ready_reg;
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Data path for src_to_dst (needs to be synchronized)
  // We need to capture the data when src_to_dst is asserted
  reg [WIDTH-1:0] src_to_dst_data;
  
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_to_dst_data <= {WIDTH{1'b0}};
    end else begin
      // Capture data when source asserts valid
      if (src_to_dst_sync[1] && !src_to_dst_sync[0]) begin
        // Rising edge of src_to_dst
        src_to_dst_data <= src_data_reg;
      end
    end
  end

endmodule
