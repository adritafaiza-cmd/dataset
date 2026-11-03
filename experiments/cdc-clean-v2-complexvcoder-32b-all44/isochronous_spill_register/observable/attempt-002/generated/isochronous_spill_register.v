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
    output [WIDTH-1:0] dst_data_o
);

    cross_clock_fifo #(
        .WIDTH(8),
        .DEPTH(2)
    ) cc_fifo_inst (
        .clk_i      (src_clk_i),
        .rst_ni     (src_rst_ni),
        .valid_i    (src_valid_i),
        .ready_o    (src_ready_o),
        .data_i     (src_data_i),
        .clk_o      (dst_clk_i),
        .rst_no     (dst_rst_ni),
        .valid_o    (dst_valid_o),
        .ready_i    (dst_ready_i),
        .data_o     (dst_data_o)
    );

endmodule

module cross_clock_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 2
)(
    input              clk_i,
    input              rst_ni,
    input              valid_i,
    output             ready_o,
    input  [WIDTH-1:0] data_i,
    input              clk_o,
    input              rst_no,
    output             valid_o,
    input              ready_i,
    output [WIDTH-1:0] data_o
);

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [1:0] head, tail;
    reg full, empty;
    reg [1:0] head_next, tail_next;
    reg valid_i_sync, ready_o_sync;
    reg valid_o_sync, ready_i_sync;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            head <= 0;
            tail <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (valid_i && !full) begin
                mem[head] <= data_i;
                head <= head_next;
                empty <= 0;
            end
            if (ready_o_sync && !empty) begin
                tail <= tail_next;
                full <= 0;
            end
            if (valid_i && !full && ready_o_sync && !empty) begin
                head <= head_next;
                tail <= tail_next;
            end
            if (valid_i && !full && ready_o_sync && !empty && (head_next == tail_next)) begin
                full <= 1;
            end
            if (!valid_i && full && !ready_o_sync && empty) begin
                empty <= 1;
            end
        end
    end

    always @(posedge clk_o or negedge rst_no) begin
        if (!rst_no) begin
            valid_o_sync <= 0;
            ready_i_sync <= 0;
        end else begin
            valid_o_sync <= valid_i;
            ready_i_sync <= ready_i;
        end
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            valid_o <= 0;
            ready_i <= 0;
        end else begin
            valid_o <= valid_o_sync;
            ready_i <= ready_i_sync;
        end
    end

    always @(*) begin
        head_next = head + 1;
        tail_next = tail + 1;
        if (head_next == DEPTH)
            head_next = 0;
        if (tail_next == DEPTH)
            tail_next = 0;
        full = (head_next == tail) && valid_i;
        empty = (head == tail) && !valid_o;
        ready_o = !full;
        valid_o_sync = valid_i;
        ready_i_sync = ready_i;
    end

    always @(*) begin
        if (!empty)
            data_o = mem[tail];
        else
            data_o = 0;
    end

endmodule
