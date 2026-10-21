module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output reg [WIDTH-1:0] dst_data_o
);

    // Depth of the spill buffer (2-deep as requested)
    localparam DEPTH = 2;

    // Source domain state
    // Stores the valid status of the current beat waiting to be transferred
    reg src_valid_reg;

    // Destination domain state
    // Stores the valid status of the current beat ready to be sent
    reg dst_valid_reg;

    // Buffer storage for data
    // We use a FIFO-like structure with pointers to manage the 2-deep buffer
    // src_ptr: Points to the next available slot in the buffer for writing
    reg [1:0] src_ptr;
    // dst_ptr: Points to the next available slot in the buffer for reading
    reg [1:0] dst_ptr;

    // Buffer data storage
    reg [WIDTH-1:0] buffer [DEPTH-1:0];

    // Full flag: Buffer is full (src_ptr == dst_ptr)
    reg src_full;
    // Empty flag: Buffer is empty (src_ptr == dst_ptr)
    reg src_empty;

    // ------------------------------------------------------------------
    // Source Domain Logic
    // ------------------------------------------------------------------
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            src_ptr       <= 2'b00;
            src_full      <= 1'b0;
            src_empty     <= 1'b1;
        end else begin
            // Update internal valid register based on input
            src_valid_reg <= src_valid_i;

            // Calculate full/empty status
            src_full <= (src_ptr == dst_ptr);
            src_empty <= (src_ptr == dst_ptr);

            // Write logic: If not full and valid data arrives
            if (!src_full && src_valid_i) begin
                buffer[src_ptr] <= src_data_i;
                src_ptr <= src_ptr + 1'b1;
                src_ready_o <= 1'b1;
            end else begin
                src_ready_o <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Destination Domain Logic
    // ------------------------------------------------------------------
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_ptr       <= 2'b00;
            src_full      <= 1'b0; // Read from source domain, safe due to CDC
            src_empty     <= 1'b1; // Read from source domain, safe due to CDC
        end else begin
            // Read logic: If not empty and destination is ready
            if (!src_empty && dst_ready_i) begin
                // Read data from the buffer at the current dst_ptr
                dst_data_o <= buffer[dst_ptr];
                dst_ptr <= dst_ptr + 1'b1;
                dst_valid_reg <= 1'b1;
            end else begin
                dst_valid_reg <= 1'b0;
                // dst_data_o is driven by the read logic above, no need to assign here
            end

            // Update full/empty status (read from source domain)
            // Since src_ptr and dst_ptr are single-bit increments and we only read
            // the equality state, this is safe across clock domains.
            src_full <= (src_ptr == dst_ptr);
            src_empty <= (src_ptr == dst_ptr);
        end
    end

    // ------------------------------------------------------------------
    // Output Logic
    // ------------------------------------------------------------------
    // src_ready_o is driven in the source domain logic above.
    // dst_valid_o is driven by the internal dst_valid_reg.
    assign dst_valid_o = dst_valid_reg;

endmodule<|im_end|>
