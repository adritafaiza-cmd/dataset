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

  // Internal signals for the 4-phase handshake
  // req: source -> destination (asserted when source has data)
  // ack: destination -> source (asserted when destination has accepted data)
  
  // Source side state
  reg src_req;
  reg [WIDTH-1:0] src_data_reg;
  
  // Destination side state
  reg dst_ack;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  
  // Synchronizers for req (src -> dst)
  reg [1:0] req_sync;
  wire req_synced = req_sync[1];
  
  // Synchronizers for ack (dst -> src)
  reg [1:0] ack_sync;
  wire ack_synced = ack_sync[1];
  
  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req <= 1'b0;
      src_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
    end else begin
      // If not currently in a transfer (req is low), and source has valid data, start transfer
      if (!src_req && src_valid_i) begin
        src_req <= 1'b1;
        src_data_reg <= src_data_i;
      end
      // If in a transfer (req is high) and ack has been received, complete transfer
      else if (src_req && ack_synced) begin
        src_req <= 1'b0;
      end
    end
  end
  
  // Source ready: ready when not in a transfer, or when ack has been received
  assign src_ready_o = !src_req || ack_synced;
  
  // Synchronize req from source to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync <= 2'b00;
    end else begin
      req_sync <= {req_sync[0], src_req};
    end
  end
  
  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack <= 1'b0;
      dst_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      // If req is asserted and we haven't acknowledged yet, accept the data
      if (req_synced && !dst_ack) begin
        dst_ack <= 1'b1;
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end
      // If we have acknowledged and the receiver is ready, complete the transfer
      else if (dst_ack && dst_ready_i) begin
        dst_ack <= 1'b0;
        dst_valid_reg <= 1'b0;
      end
    end
  end
  
  // Destination valid: valid when we have accepted data and haven't been consumed yet
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  
  // Synchronize ack from destination to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync <= 2'b00;
    end else begin
      ack_sync <= {ack_sync[0], dst_ack};
    end
  end

endmodule
