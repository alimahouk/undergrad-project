package pmpp;

import java.awt.EventQueue;

import javax.swing.JFrame;
import javax.swing.JLabel;
import java.awt.BorderLayout;
import javax.swing.SwingConstants;
import java.awt.Font;
import javax.swing.JButton;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

public class PingamateJava {

	private JFrame frame;

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					PingamateJava window = new PingamateJava();
					window.frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Create the application.
	 */
	public PingamateJava() {
		initialize();
	}

	/**
	 * Initialize the contents of the frame.
	 */
	private void initialize() {
		frame = new JFrame();
		frame.setBounds(100, 100, 450, 300);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		
		JLabel lblPingamate = new JLabel("Pingamate");
		lblPingamate.setFont(new Font("Courier New", Font.PLAIN, 30));
		lblPingamate.setHorizontalAlignment(SwingConstants.CENTER);
		frame.getContentPane().add(lblPingamate, BorderLayout.NORTH);
				
		JButton btnStart = new JButton("Start");
		btnStart.setFont(new Font("Courier New", Font.PLAIN, 30));
		frame.getContentPane().add(btnStart, BorderLayout.CENTER);
		btnStart.addActionListener(new btnStartActionListener());
	}
	
    class btnStartActionListener implements ActionListener {
        public void actionPerformed(ActionEvent event) {
        	Main obj = new Main();
        	obj.setVisible(true);
            }
        }
}
