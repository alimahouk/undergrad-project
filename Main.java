package pmpp;

import java.awt.BorderLayout;
import java.awt.EventQueue;
import java.awt.Font;

import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.border.EmptyBorder;
import javax.swing.JSplitPane;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.SwingConstants;
import javax.swing.JTextField;
import javax.swing.JList;
import java.awt.Color;
import javax.swing.AbstractListModel;
import javax.swing.ListSelectionModel;
import javax.swing.border.BevelBorder;
import javax.swing.JTextArea;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;

public class Main extends JFrame {

	private JPanel contentPane;
	private JTextField textField;

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					Main frame = new Main();
					frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Create the frame.
	 */
	public Main() {
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setBounds(100, 100, 450, 300);
		contentPane = new JPanel();
		contentPane.setBorder(new EmptyBorder(5, 5, 5, 5));
		contentPane.setLayout(new BorderLayout(0, 0));
		setContentPane(contentPane);
		
		JSplitPane splitPane = new JSplitPane();
		contentPane.add(splitPane, BorderLayout.NORTH);
		
		JButton btnBack = new JButton("Back");
		splitPane.setLeftComponent(btnBack);
		
		JList list = new JList();
		list.setBorder(new BevelBorder(BevelBorder.LOWERED, null, null, null, null));
		list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
		list.setModel(new AbstractListModel() {
			String[] values = new String[] {"Ibrahim", "Ali", "Ahmed", "Karan", "Vishal"};
			public int getSize() {
				return values.length;
			}
			public Object getElementAt(int index) {
				return values[index];
			}
		});
		list.setSelectedIndex(0);
		list.setBackground(Color.WHITE);
		contentPane.add(list, BorderLayout.WEST);
		
		JLabel heading = new JLabel("Ibrahim");
		heading.setHorizontalAlignment(SwingConstants.CENTER);
		splitPane.setRightComponent(heading);
				
		JSplitPane splitPane_1 = new JSplitPane();
		splitPane_1.setResizeWeight(1.0);
		contentPane.add(splitPane_1, BorderLayout.SOUTH);
		
		textField = new JTextField();
		splitPane_1.setLeftComponent(textField);
		textField.setColumns(10);
		
		JTextArea textArea = new JTextArea();
		textArea.setForeground(Color.GREEN);
		textArea.setBackground(Color.BLACK);
		contentPane.add(textArea, BorderLayout.CENTER);
		textArea.setFont(new Font("Courier New", Font.PLAIN, 15));
		textArea.setEditable(false);
		
		MouseListener mouseListener = new MouseAdapter() {
		    public void mouseClicked(MouseEvent e) {
		    	if(e.getClickCount() == 1)
		    	{
		    		int name = list.getSelectedIndex();
		    		String namestr = ""; 
		    		if (name == 0)
		    		{
		    			namestr = "Ibrahim";
		    			heading.setText(namestr);
		    			textArea.setText("");
		    		}
		    		else if (name == 1)
		    		{
		    			namestr = "Ali";
		    			heading.setText(namestr);
		    			textArea.setText("");
		    		}
		    		else if (name == 2)
		    		{
		    			namestr = "Ahmed";
		    			heading.setText(namestr);
		    			textArea.setText("");
		    		} 
		    		else if (name == 3)
		    		{
		    			namestr = "Karan";
		    			heading.setText(namestr);
		    			textArea.setText("");
		    		} 
		    		else 
		    		{
		    			namestr = "Vishal";
		    			heading.setText(namestr);
		    			textArea.setText("");
		    		} 
		    	}
		    }
		};
		list.addMouseListener(mouseListener);
		
		JButton btnSend = new JButton("Send");
		btnSend.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
	            if (textField.getText().length() < 1) {
	                // do nothing
	            } else if (textField.getText().equals(".clear")) {
	                textArea.setText("Cleared all messages\n");
	                textField.setText("");
	            } else {
	                textArea.append("Me: " + textField.getText()
	                        + "\n");
	                textField.setText("");
	            }
	            textField.requestFocusInWindow();
			}
		});
		splitPane_1.setRightComponent(btnSend);
		
		textField.addKeyListener(new KeyAdapter(){
			public void keyPressed(KeyEvent e){
			    if (e.getKeyCode() == KeyEvent.VK_ENTER){
			   //on enter key 
		            if (textField.getText().length() < 1) {
		                // do nothing
		            } else if (textField.getText().equals(".clear")) {
		                textArea.setText("Cleared all messages\n");
		                textField.setText("");
		            } else {
		                textArea.append("Me: " + textField.getText()
		                        + "\n");
		                textField.setText("");
		            }
		            textField.requestFocusInWindow();	
			    }
			}
		});
		
		btnBack.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				dispose();
			}
		});
	}

}
