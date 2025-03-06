package pmpp;

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

public class PingamateJava {

	private JFrame frame;
	private JLabel lblPingamate = new JLabel("Pingamate");
	private JMenuBar menuBar = new JMenuBar();
	private JMenuItem mntmChats = new JMenuItem("Chats");
	private JMenuItem mntmProfile = new JMenuItem("Profile");
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
		frame.setBounds(100, 100, 500, 300);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		
		lblPingamate.setFont(new Font("Courier New", Font.PLAIN, 30));
		lblPingamate.setHorizontalAlignment(SwingConstants.CENTER);
		frame.getContentPane().add(lblPingamate, BorderLayout.NORTH);
		
		frame.setJMenuBar(menuBar);
		mntmAbout.setHorizontalAlignment(SwingConstants.CENTER);
		menuBar.add(mntmAbout);
		mntmAbout.addActionListener(abt);
		mntmChats.setHorizontalAlignment(SwingConstants.CENTER);
		menuBar.add(mntmChats);
		mntmContacts.setHorizontalAlignment(SwingConstants.CENTER);
		
		menuBar.add(mntmContacts);
		mntmProfile.setHorizontalAlignment(SwingConstants.CENTER);
		menuBar.add(mntmProfile);
		mntmChats.addActionListener(chats);
		mntmProfile.addActionListener(pro);
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

}
