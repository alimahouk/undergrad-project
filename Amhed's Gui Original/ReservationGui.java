package guis;

import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.border.EmptyBorder;

import java.awt.GridLayout;

import javax.swing.JButton;

import main.Client;
import utilities.AllReservations;
import utilities.CurrentDate;
import utilities.Reservation;
import utilities.TimeSlotButton;

import java.awt.Color;
import java.sql.Date;
import java.sql.Time;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.ArrayList;
import java.awt.Font;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowEvent;
import java.io.IOException;

public class ReservationGui extends JFrame 
{

	private static final long serialVersionUID = 1L;

	ActionListener al;
	
	private JPanel contentPane;
	private JPanel panelTime;
	private JPanel panelReservations;
	private JPanel panelDays;
	private JPanel panelWeek;
	private JPanel panelCurrentDate;
	
	private JButton btnPreviousWeek;
	private JButton btnNextWeek;
	private JButton btnSetReservation;
	private JButton btnReserve;
	private JButton btnCancelReservation;
	
	private JLabel lblDate;
	private JLabel lblCurrentDay;
	private JLabel lblCurrentDate;
	
	private TimeSlotButton[][] timeSlots;
	private JLabel[] lblDays;
	
	private Date[] date;
	private Time[] time;
	
	private int clientID;
	
	DateFormat df1 = new SimpleDateFormat("u");
	DateFormat df2 = new SimpleDateFormat("EEEE");
	DateFormat df3 = new SimpleDateFormat("dd/MM/yyyy");
	
	private AllReservations allReservations;

	private TimeSlotButton btnSelected;
	private int duration;
	private Reservation reservation;
	private Boolean reservationSet = false;
	
	public Boolean reservationWasSet()
	{
		return reservationSet;
	}
	
	public void reservationUnset()
	{
		reservationSet = false;;
	}
	
	public Reservation getReservation()
	{
		return reservation;
	}
	
	public void showMessage(String message)
	{
		JOptionPane.showMessageDialog(null, message);
	}
	
	public void addDays()
	{
		panelDays.removeAll();
		for (int i=0; i<7; i++)
		{
			lblDays[i] = new JLabel(df2.format(date[i]));
			lblDays[i].setForeground(Color.LIGHT_GRAY);
			lblDays[i].setHorizontalAlignment(SwingConstants.CENTER);
			panelDays.add(lblDays[i]);
		}
		for (int i=0; i<7; i++)
		{
			lblDays[i] = new JLabel(df3.format(date[i]));
			lblDays[i].setForeground(Color.LIGHT_GRAY);
			lblDays[i].setHorizontalAlignment(SwingConstants.CENTER);
			panelDays.add(lblDays[i]);
		}
		panelDays.revalidate();
	}
	
	public void addTimeSlots()
	{
		ArrayList<TimeSlotButton> r1 = new ArrayList<TimeSlotButton>();
		ArrayList<TimeSlotButton> r2 = new ArrayList<TimeSlotButton>();
		
		for (int i=0; i<28; i++)
		{
			for (int j=0; j<7; j++)
			{
				timeSlots[j][i] = new TimeSlotButton(j, i, date[j], time[i], false, al);
			}
		}
		
		for (int i=0; i<allReservations.size(); i++)
		{
			int day = allReservations.get(i).day;
			int t = 0;
			for (int j=0; j<time.length; j++)
			{
				if (time[j].equals(allReservations.get(i).begin))
					t = j;
			}
			
			if (allReservations.get(i).date.equals(timeSlots[day][t].date))
			{
				timeSlots[day][t].setReserved();
				timeSlots[day][t].setName(allReservations.get(i).reservedBy);
				if (allReservations.get(i).clientID==clientID)
				{
					timeSlots[day][t].reservedByMe = true;
					timeSlots[day][t].setName("My Reservation");
					timeSlots[day][t].setInitial();
				}
				r1.add(timeSlots[day][t]);
			}
			
			for (int j=0; j<time.length; j++)
			{
				if (time[j].equals(allReservations.get(i).end))
					t = j - 1;
			}
			if (allReservations.get(i).date.equals(timeSlots[day][t].date))
			{
				timeSlots[day][t].setReserved();
				r2.add(timeSlots[day][t]);
			}
		}
		
		
		for (int i=0; i<28; i++)
		{
			for (int j=0; j<7; j++)
			{
				for (int k=0; k<r1.size(); k++)
				{
					if (timeSlots[j][i].begin.after(r1.get(k).begin)
							&& timeSlots[j][i].begin.before(r2.get(k).begin)
							&& j==r1.get(k).day && timeSlots[j][i].date.equals(r1.get(k).date))
					{
						timeSlots[j][i].setReserved();
					}
				}
			}
		}
	
		panelReservations.removeAll();
		for (int i=0; i<28; i++)
		{
			for (int j=0; j<7; j++)
			{
				panelReservations.add(timeSlots[j][i]);
			}
		}
		
		panelReservations.revalidate();
	}
	
	public void previousWeek()
	{
		for (int i=0; i<7; i++)
		{
			date[i].setTime(date[i].getTime() - 7*24*3600000);
		}
	}
	
	public void nextWeek()
	{
		for (int i=0; i<7; i++)
		{
			date[i].setTime(date[i].getTime() + 7*24*3600000);
		}
	}

	public void handleSelection()
	{		
		for (int i=0; i<28; i++)
		{
			for (int j=0; j<7; j++)
			{
				if(timeSlots[j][i].selected)
				{
					timeSlots[j][i].setSelected();
				}
			}
		}
	}
	
	public Reservation getSelection(TimeSlotButton btn, int c)
	{
		Reservation reservation = null;
		
		reservation = new Reservation(btn.day, btn.date, btn.begin,
							new Time(btn.begin.getTime() + (1+c)*1800000), "byUser");
		return reservation;
	}
	
	public void launchDurationGui()
	{
		for (int i=0; i<28; i++)
		{
			for (int j=0; j<7; j++)
			{
				if(timeSlots[j][i].selected)
				{
					ActionListener al = null;
					btnSelected = new TimeSlotButton(timeSlots[j][i].day, timeSlots[j][i].timeSlot, timeSlots[j][i].date,
							timeSlots[j][i].begin, false, al);
				}
			}
		}
		int slot = btnSelected.timeSlot;
		while (slot<28 && !timeSlots[btnSelected.day][slot].reserved)
		{
			slot++;
		}
		
		int c = 0;
		for (int i=0; i<(slot-btnSelected.timeSlot); i++)
		{
			c++;
		}
		
		c = 8 - c;
		ArrayList<String> durations = new ArrayList<String>();
		durations.add("30 mins");
		durations.add("1 h");
		durations.add("1 h 30 mins");
		durations.add("2 h");
		durations.add("2 h 30 mins");
		durations.add("3 h");
		durations.add("3 h 30 mins");
		durations.add("4 h");
		
		if (c<9)
		{
			for (int i=0; i<c; i++)
			{
				durations.remove(durations.size()-1);
			}
		}
		
		DurationGui durationGui = new DurationGui(durations);
		durationGui.addOkActionListener(new ActionListener() {

			public void actionPerformed(ActionEvent e) 
			{
				duration = durationGui.getSelection();
				durationGui.dispatchEvent(new WindowEvent(durationGui, WindowEvent.WINDOW_CLOSING));
				
				reservation = getSelection(btnSelected, duration);
				
				reservationSet = true;
			}
			
		});
		durationGui.addCancelActionListener(new ActionListener() 
		{
			public void actionPerformed(ActionEvent e) 
			{
				durationGui.dispatchEvent(new WindowEvent(durationGui, WindowEvent.WINDOW_CLOSING));
			}
			
		});
	}
	
	public void setReservations(AllReservations allReservations)
	{
		this.allReservations = new AllReservations(allReservations);
	}
	
	public ReservationGui(Client client, int clientID, AllReservations allReservations, ActionListener alReserve) 
	{
		this.clientID = clientID;
		this.allReservations = new AllReservations(allReservations);
		setResizable(false);
		setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		setBounds(1, 1, 900, 723);
		contentPane = new JPanel();
		contentPane.setBackground(Color.DARK_GRAY);
		contentPane.setBorder(new EmptyBorder(5, 5, 5, 5));
		setContentPane(contentPane);
		contentPane.setLayout(null);
		
		panelTime = new JPanel();
		panelTime.setBackground(Color.DARK_GRAY);
		panelTime.setBorder(null);
		panelTime.setBounds(10, 112, 103, 548);
		contentPane.add(panelTime);
		panelTime.setLayout(new GridLayout(28, 1, 0, 2));
		
		panelReservations = new JPanel();
		panelReservations.setBackground(Color.DARK_GRAY);
		panelReservations.setBounds(123, 112, 761, 548);
		contentPane.add(panelReservations);
		panelReservations.setLayout(new GridLayout(28, 7, 5, 2));
		
		panelDays = new JPanel();
		panelDays.setBackground(Color.DARK_GRAY);
		panelDays.setBounds(123, 46, 761, 55);
		contentPane.add(panelDays);
		panelDays.setLayout(new GridLayout(2, 7, 0, 0));
		
		panelWeek = new JPanel();
		panelWeek.setBackground(Color.DARK_GRAY);
		panelWeek.setBounds(123, 11, 761, 23);
		contentPane.add(panelWeek);
		panelWeek.setLayout(null);
		
		panelCurrentDate = new JPanel();
		panelCurrentDate.setBackground(Color.DARK_GRAY);
		panelCurrentDate.setBounds(10, 11, 103, 90);
		contentPane.add(panelCurrentDate);
		panelCurrentDate.setLayout(null);
		
		btnPreviousWeek = new JButton("Previous Week");
		btnPreviousWeek.addActionListener(new ActionListener()
		{
			public void actionPerformed(ActionEvent e) 
			{
				previousWeek();
				addDays();
				addTimeSlots();
			}
			
		});
		btnPreviousWeek.setBounds(0, 0, 161, 23);
		panelWeek.add(btnPreviousWeek);
		
		btnNextWeek = new JButton("Next Week");
		btnNextWeek.addActionListener(new ActionListener()
		{
			public void actionPerformed(ActionEvent e) 
			{
				nextWeek();
				addDays();
				addTimeSlots();
			}
			
		});
		btnNextWeek.setBounds(600, 0, 161, 23);
		panelWeek.add(btnNextWeek);
		
		btnCancelReservation = new JButton("Cancel Reservation");
		btnCancelReservation.setBounds(473, 660, 150, 30);
		btnCancelReservation.addActionListener(new ActionListener() 
		{

			public void actionPerformed(ActionEvent e) 
			{
				Boolean somethingSelected = false;
				for (int i=0; i<28; i++)
				{
					for (int j=0; j<7; j++)
					{
						if (timeSlots[j][i].clickedByMe)
						{
							somethingSelected = true;
						}
					}
				}
				
				if (somethingSelected)
				{
					for (int i=0; i<28; i++)
					{
						for (int j=0; j<7; j++)
						{
							if(timeSlots[j][i].clickedByMe)
							{
								
								btnSelected = new TimeSlotButton(timeSlots[j][i].day, timeSlots[j][i].timeSlot, timeSlots[j][i].date,
										timeSlots[j][i].begin, false, al);
								reservation = getSelection(btnSelected, 0);
								
								try 
								{
									client.getOutputStream().writeObject("$ cancel reservation");
									client.getOutputStream().flush();
									
									client.getOutputStream().writeObject(reservation);
									client.getOutputStream().flush();
									
								} 
								catch (IOException e1) 
								{
									e1.printStackTrace();
								}
							}
						}
					}
				}
				else
				{
					showMessage("No selected reservations to cancel.");
				}
			}
			
		});
		contentPane.add(btnCancelReservation);
		
		btnSetReservation = new JButton("Set Reservation");
		btnSetReservation.addActionListener(new ActionListener() 
		{
			public void actionPerformed(ActionEvent e) 
			{
				Boolean somethingSelected = false;
				Boolean validSelection = false;
				CurrentDate today = new CurrentDate();
				for (int i=0; i<28; i++)
				{
					for (int j=0; j<7; j++)
					{
						if (timeSlots[j][i].selected)
						{
							somethingSelected = true;
							
							if ((timeSlots[j][i].begin.getTime()+timeSlots[j][i].date.getTime()+ 4*3600000) > today.getTime())
							{
								validSelection = true;
							}
						}
					}
				}
				if (somethingSelected && validSelection)
					launchDurationGui();
				else
				{
					if (!somethingSelected)
						showMessage("Select a time before setting the reservation.");
					else
						showMessage("The time you selected is already past.");
				}
			}
			
		});
		
		btnSetReservation.setBounds(635, 660, 150, 30);
		contentPane.add(btnSetReservation);
		
		btnReserve = new JButton("Reserve");
		btnReserve.addActionListener(alReserve);
		btnReserve.setBounds(797, 660, 85, 30);
		contentPane.add(btnReserve);
		
		
		al = new ActionListener()
		{
			public void actionPerformed(ActionEvent e) 
			{
				handleSelection();
			}	
		};
		
		lblDays = new JLabel[7];
		timeSlots = new TimeSlotButton[7][28];
		
		CurrentDate currentDate = new CurrentDate();
		Calendar cal = Calendar.getInstance();
		cal.setTime(currentDate);
		cal.set(Calendar.HOUR_OF_DAY, 0);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		currentDate.setTime(cal.getTimeInMillis());
		
		date = new Date[7];
		for (int i=0; i<7; i++)
		{
			date[i] = new Date(currentDate.getTime());
		}
		int d = Integer.parseInt(df1.format(date[0])); d--;
		for (int i=0; i<d; i++)
		{
			date[i].setTime(date[d].getTime() - (d-i)*3600000*24);
		}
		for (int i=1; (d+i)<7; i++)
		{
			date[d+i].setTime(date[d].getTime() + i*3600000*24);
		}
		
		addDays();
		
		
		time = new Time[29];
		time[0] = new Time(4*3600000);
		for (int i=1; i<29; i++)
		{
			time[i] = new Time(time[i-1].getTime()+ 1800000);
		}
		for (int i=0; i<28; i++)
		{
			JLabel lbl = new JLabel(time[i].toString() + "-" + time[i+1].toString());
			lbl.setAlignmentX(CENTER_ALIGNMENT);
			lbl.setForeground(Color.LIGHT_GRAY);
			panelTime.add(lbl);
		}
		addTimeSlots();
		
		lblDate = new JLabel("Current date:");
		lblDate.setFont(new Font("Tahoma", Font.ITALIC, 12));
		lblDate.setForeground(Color.LIGHT_GRAY);
		lblDate.setBounds(0, 0, 103, 14);
		panelCurrentDate.add(lblDate);
		
		lblCurrentDay = new JLabel(df2.format(date[d]));
		lblCurrentDay.setForeground(Color.LIGHT_GRAY);
		lblCurrentDay.setBounds(0, 25, 103, 14);
		panelCurrentDate.add(lblCurrentDay);
		
		lblCurrentDate = new JLabel(df3.format(date[d]));
		lblCurrentDate.setForeground(Color.LIGHT_GRAY);
		lblCurrentDate.setBounds(0, 40, 103, 14);
		panelCurrentDate.add(lblCurrentDate);
		
		setVisible(true);
	}
}
