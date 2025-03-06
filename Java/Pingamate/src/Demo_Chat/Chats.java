package Demo_Chat;

import java.awt.BorderLayout;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JPanel;
import javax.swing.border.EmptyBorder;
import javax.swing.JSplitPane;
import javax.swing.JLabel;
import javax.swing.SwingConstants;
import javax.swing.JTextField;
import javax.swing.JList;
import javax.swing.AbstractListModel;
import javax.swing.border.BevelBorder;
import javax.swing.ListSelectionModel;
import javax.swing.JTextArea;
import java.awt.Color;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.ActionEvent;

@SuppressWarnings("serial")
public class Chats extends JDialog {

	private final JPanel contentPanel = new JPanel();
	private JTextField textField;

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		try {
			Chats dialog = new Chats();
			dialog.setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
			dialog.setVisible(true);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * Create the dialog.
	 */
	@SuppressWarnings({ "unchecked", "rawtypes" })
	public Chats() {
		setForeground(Color.LIGHT_GRAY);
		setBackground(Color.DARK_GRAY);
		setBounds(100, 100, 450, 300);
		getContentPane().setLayout(new BorderLayout());
		contentPanel.setBorder(new EmptyBorder(5, 5, 5, 5));
		getContentPane().add(contentPanel, BorderLayout.CENTER);
		contentPanel.setLayout(new BorderLayout(0, 0));
		
		JSplitPane splitPane = new JSplitPane();
		splitPane.setForeground(Color.LIGHT_GRAY);
		splitPane.setBackground(Color.DARK_GRAY);
		contentPanel.add(splitPane, BorderLayout.NORTH);
		
		JButton btnHome = new JButton("Home");
		btnHome.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				dispose(); 
			}
		});
		splitPane.setLeftComponent(btnHome);
		
		final JLabel lblHeading = new JLabel("");
		lblHeading.setHorizontalAlignment(SwingConstants.CENTER);
		splitPane.setRightComponent(lblHeading);
		
		JSplitPane splitPane_1 = new JSplitPane();
		splitPane_1.setResizeWeight(1.0);
		contentPanel.add(splitPane_1, BorderLayout.SOUTH);
		
		textField = new JTextField();
		textField.setForeground(Color.LIGHT_GRAY);
		textField.setBackground(Color.DARK_GRAY);
		splitPane_1.setLeftComponent(textField);
		textField.setColumns(10);
		
		JButton btnSend = new JButton("Send");
		
		final JList list = new JList();
		list.setForeground(Color.LIGHT_GRAY);
		list.setBackground(Color.DARK_GRAY);
		list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
		list.setBorder(new BevelBorder(BevelBorder.LOWERED, null, null, null, null));
		list.setModel(new AbstractListModel() {
			String[] values = new String[] {"Ahmed", "Ali ", "Ibrahim", "Karan", "Vishal"};
			public int getSize() {
				return values.length;
			}
			public Object getElementAt(int index) {
				return values[index];
			}
		});
		list.setSelectedIndex(-1);
		contentPanel.add(list, BorderLayout.WEST);
		
		final JTextArea textArea = new JTextArea();
		textArea.setForeground(Color.LIGHT_GRAY);
		textArea.setBackground(Color.DARK_GRAY);
		contentPanel.add(textArea, BorderLayout.CENTER);
		
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
		
		textField.addKeyListener(new KeyListener(){
			public void keyPressed(KeyEvent e){
				if(e.getKeyChar() == KeyEvent.VK_ENTER)
				{
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
			

			@Override
			public void keyTyped(KeyEvent e) {
				// TODO Auto-generated method stub
				
			}

			@Override
			public void keyReleased(KeyEvent e) {
				// TODO Auto-generated method stub
				
			}
	     });
		
		list.addMouseListener(new MouseListener() {

			@Override
			public void mouseClicked(MouseEvent e) {
				// TODO Auto-generated method stub
				if (e.getClickCount() == 1)
				{
					String name = (String) list.getSelectedValue();
					lblHeading.setText(name);
					textArea.setText("");
				}
			}

			@Override
			public void mousePressed(MouseEvent e) {
				// TODO Auto-generated method stub
				
			}

			@Override
			public void mouseReleased(MouseEvent e) {
				// TODO Auto-generated method stub
				
			}

			@Override
			public void mouseEntered(MouseEvent e) {
				// TODO Auto-generated method stub
				
			}

			@Override
			public void mouseExited(MouseEvent e) {
				// TODO Auto-generated method stub
				
			}
		});
	}

}
