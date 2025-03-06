package Demo_Chat;

import java.awt.EventQueue;

import javax.swing.JFrame;
import javax.swing.JLabel;
import java.awt.BorderLayout;
import javax.swing.SwingConstants;
import java.awt.Font;

import javax.swing.AbstractAction;
import java.awt.event.ActionEvent;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JPanel;
import java.awt.GridBagLayout;
import java.awt.GridBagConstraints;
import java.awt.Insets;
import java.awt.Color;

public class PingamateJava {

	private JFrame frame;
	private JLabel lblPingamate = new JLabel("Pingamate");
	private JMenuBar menuBar = new JMenuBar();
	private JMenuItem mntmChats = new JMenuItem("Chats");
	private JMenuItem mntmAbout = new JMenuItem("About");
	private JMenuItem mntmContacts = new JMenuItem("Contacts");

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
		frame.getContentPane().setBackground(Color.DARK_GRAY);
		frame.setBackground(Color.DARK_GRAY);
		frame.setBounds(100, 100, 500, 300);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		lblPingamate.setForeground(Color.LIGHT_GRAY);
		lblPingamate.setBackground(Color.DARK_GRAY);
		
		lblPingamate.setFont(new Font("Courier New", Font.PLAIN, 30));
		lblPingamate.setHorizontalAlignment(SwingConstants.CENTER);
		frame.getContentPane().add(lblPingamate, BorderLayout.SOUTH);
		label.setForeground(Color.LIGHT_GRAY);
		label.setBackground(Color.DARK_GRAY);
		label.setHorizontalAlignment(SwingConstants.CENTER);
		label.setFont(new Font("Courier New", Font.PLAIN, 30));
		
		frame.getContentPane().add(label, BorderLayout.NORTH);
		panel.setBackground(Color.DARK_GRAY);
		
		frame.getContentPane().add(panel, BorderLayout.CENTER);
		GridBagLayout gbl_panel = new GridBagLayout();
		gbl_panel.columnWidths = new int[]{0, 0};
		gbl_panel.rowHeights = new int[]{0, 0, 0, 0, 0, 0, 0};
		gbl_panel.columnWeights = new double[]{0.0, Double.MIN_VALUE};
		gbl_panel.rowWeights = new double[]{0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Double.MIN_VALUE};
		panel.setLayout(gbl_panel);
		
		GridBagConstraints gbc_label_1 = new GridBagConstraints();
		gbc_label_1.insets = new Insets(0, 0, 5, 0);
		gbc_label_1.gridx = 0;
		gbc_label_1.gridy = 0;
		label_1.setForeground(Color.LIGHT_GRAY);
		label_1.setBackground(Color.DARK_GRAY);
		panel.add(label_1, gbc_label_1);
		
		GridBagConstraints gbc_label_2 = new GridBagConstraints();
		gbc_label_2.insets = new Insets(0, 0, 5, 0);
		gbc_label_2.gridx = 0;
		gbc_label_2.gridy = 1;
		label_2.setForeground(Color.LIGHT_GRAY);
		label_2.setBackground(Color.DARK_GRAY);
		panel.add(label_2, gbc_label_2);
		
		GridBagConstraints gbc_label_3 = new GridBagConstraints();
		gbc_label_3.insets = new Insets(0, 0, 5, 0);
		gbc_label_3.gridx = 0;
		gbc_label_3.gridy = 2;
		label_3.setForeground(Color.LIGHT_GRAY);
		label_3.setBackground(Color.DARK_GRAY);
		panel.add(label_3, gbc_label_3);
		
		GridBagConstraints gbc_label_4 = new GridBagConstraints();
		gbc_label_4.insets = new Insets(0, 0, 5, 0);
		gbc_label_4.gridx = 0;
		gbc_label_4.gridy = 3;
		label_4.setForeground(Color.LIGHT_GRAY);
		label_4.setBackground(Color.DARK_GRAY);
		panel.add(label_4, gbc_label_4);
		menuBar.setBackground(Color.DARK_GRAY);
		
		frame.setJMenuBar(menuBar);
		mntmAbout.setBackground(Color.DARK_GRAY);
		mntmAbout.setHorizontalAlignment(SwingConstants.CENTER);
		menuBar.add(mntmAbout);
		mntmAbout.addActionListener(abt);
		mntmChats.setBackground(Color.DARK_GRAY);
		mntmChats.setHorizontalAlignment(SwingConstants.CENTER);
		menuBar.add(mntmChats);
		mntmContacts.setBackground(Color.DARK_GRAY);
		mntmContacts.setHorizontalAlignment(SwingConstants.CENTER);
		
		menuBar.add(mntmContacts);
		mntmChats.addActionListener(chats);
		mntmContacts.addActionListener(con);
	}
	
	@SuppressWarnings("serial")
	AbstractAction abt = new AbstractAction("About Page") {
	    public void actionPerformed(ActionEvent e) {
	        // Button pressed logic goes here
	    	About obj = new About(); 
	    	obj.setVisible(true);
	    }
	};
	
	@SuppressWarnings("serial")
	AbstractAction chats = new AbstractAction("Chat Page") {
	    public void actionPerformed(ActionEvent e) {
	        // Button pressed logic goes here
        	Chats obj = new Chats();
        	obj.setVisible(true);
	    }
	};
	
	@SuppressWarnings("serial")
	AbstractAction pro = new AbstractAction("Profile Page") {
	    public void actionPerformed(ActionEvent e) {
	        // Button pressed logic goes here
        	Profile obj = new Profile();
        	obj.setVisible(true);
	    }
	};
	
	@SuppressWarnings("serial")
	AbstractAction con = new AbstractAction("Contacts Page") {
	    public void actionPerformed(ActionEvent e) {
	        // Button pressed logic goes here
        	Contacts obj = new Contacts();
        	obj.setVisible(true);
	    }
	};
	private final JLabel label = new JLabel("My Profile");
	private final JPanel panel = new JPanel();
	private final JLabel label_1 = new JLabel("Username:");
	private final JLabel label_2 = new JLabel("Status:");
	private final JLabel label_3 = new JLabel("IP Address:");
	private final JLabel label_4 = new JLabel("Display Picture:");

}
