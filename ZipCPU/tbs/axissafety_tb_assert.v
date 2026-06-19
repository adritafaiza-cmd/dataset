`timescale 1ns/1ps
// Assertion-enhanced starter testbench generated for simulation + protocol checking.
`default_nettype none
module axissafety_assert;
    localparam DW=8, UW=1;
    reg clk=0, rstn=0; always #5 clk=~clk; integer errors=0;
    wire fault; reg s_valid; wire s_ready; reg [DW-1:0] s_data; reg s_last; reg [UW-1:0] s_user;
    wire m_valid; reg m_ready; wire [DW-1:0] m_data; wire m_last; wire [UW-1:0] m_user;
    axissafety #(.C_AXIS_DATA_WIDTH(DW),.C_AXIS_USER_WIDTH(UW),.OPT_MAX_STALL(4),.OPT_PACKET_LENGTH(0),.OPT_SELF_RESET(0)) dut(
        .o_fault(fault),.S_AXI_ACLK(clk),.S_AXI_ARESETN(rstn),.S_AXIS_TVALID(s_valid),.S_AXIS_TREADY(s_ready),.S_AXIS_TDATA(s_data),.S_AXIS_TLAST(s_last),.S_AXIS_TUSER(s_user),
        .M_AXIS_TVALID(m_valid),.M_AXIS_TREADY(m_ready),.M_AXIS_TDATA(m_data),.M_AXIS_TLAST(m_last),.M_AXIS_TUSER(m_user));
    task check; input cond; input [255:0] msg; begin if(!cond) begin $display("FAIL: %s",msg); errors=errors+1; end else $display("PASS: %s",msg); end endtask
    initial begin
        s_valid=0; s_data=0; s_last=0; s_user=0; m_ready=1; repeat(5) @(posedge clk); rstn=1; repeat(3) @(posedge clk);
        $display("TEST AXISSAFETY");
        @(negedge clk); s_data=8'h11; s_last=0; s_valid=1; wait(s_ready); @(negedge clk); s_data=8'h22; s_last=1; wait(s_ready); @(negedge clk); s_valid=0; s_last=0;
        repeat(4) @(posedge clk); check(!fault,"good stream packet no fault");
        // Backpressure long enough to trip stall timeout
        @(negedge clk); m_ready=0; s_data=8'h33; s_last=1; s_valid=1; repeat(12) @(posedge clk); check(fault,"fault asserted on stream stall timeout");
        $display(errors?"TESTS FAILED":"ALL TESTS PASSED"); $finish;
    end


  // ---------------- Assertion monitors ----------------
  // AXI-Stream payload must remain stable while TVALID is high and TREADY is low
  reg prev_stream_wait;
  reg [31:0] prev_stream_data;
  reg prev_stream_last;
  always @(posedge clk) begin
    if (!rstn) begin
      prev_stream_wait <= 1'b0; prev_stream_data <= 0; prev_stream_last <= 1'b0;
    end else begin
      if (prev_stream_wait) begin
        if (!(s_valid) else begin $display("ASSERT FAIL: TVALID dropped before TREADY")) begin $display("ASSERT FAIL: s_valid) else begin $display("ASSERT FAIL: TVALID dropped before TREADY""); errors = errors + 1; end errors = errors + 1; end
        if (!(s_data == prev_stream_data) else begin $display("ASSERT FAIL: TDATA changed while stalled")) begin $display("ASSERT FAIL: s_data == prev_stream_data) else begin $display("ASSERT FAIL: TDATA changed while stalled""); errors = errors + 1; end errors = errors + 1; end
        if (!(s_last == prev_stream_last) else begin $display("ASSERT FAIL: TLAST changed while stalled")) begin $display("ASSERT FAIL: s_last == prev_stream_last) else begin $display("ASSERT FAIL: TLAST changed while stalled""); errors = errors + 1; end errors = errors + 1; end
      end
      prev_stream_wait <= (s_valid && !s_ready);
      prev_stream_data <= s_data;
      prev_stream_last <= s_last;
    end
  end

endmodule
`default_nettype wire
