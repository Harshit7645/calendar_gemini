import 'package:calendar_gemini/constants.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../oauth/google_auth_service.dart';
import '../oauth/google_calendar_service.dart';
import 'dart:convert';  

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String apiKey = gemini_api_key;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");
  GenerativeModel? model;
  GoogleCalendarService googleCalendarService = GoogleCalendarService();

  @override
  void initState() {
    model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Gemini Calendar"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(currentUser: currentUser, onSend: _sendMessage, messages: messages);
  }

  void _sendMessage(ChatMessage chatMessage) async{
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String context = """Suppose you are a Google Calendar Scheduler app and you have 
                          to help me in classifying the intent of the user with his query 
                          and just return the following data User_Intent, Date, Start_Time, End_Time, Event_name
                          in correct JSON Format from the user's query and by default take value of 
                          all fields as null and also don't ask back any questions. Here is the list of 
                          Event_Intents from which you have to classify :-
                          { Add_Event, Shift_Event, Cancel_Event, Add_Recurring_Event, AllDay_Event, 
                          Add_Notification}.The fields required are: 
                          {
                            "User_Intent": "Add_Event",
                            "Event_name": "meeting with kavya",     // Use a valid event name, no 'undefined'.
                            "Date": "2024-10-16",                  // Use format YYYY-MM-DD. No 'undefined'.
                            "Start_Time": "17:00",                 // Use 24-hour format for time (HH:MM). No 'undefined'.
                            "End_Time": "18:00"                    // Optional field. No 'undefined', but it's ok if absent.
                          }
                          Return the data for the following user query:- """;

      String prompt = context + chatMessage.text;
      if (model != null) {
        // Create content for the prompt
        final content = [Content.text(prompt)];
        final response = await model!.generateContent(content);
        String responseText = response.text ?? 'Please ask a proper query!';
        try {
          responseText = responseText.replaceAll(RegExp(r'```json|```|\njson'), '').trim();
          responseText = responseText.replaceAll('undefined', 'null');
          print(responseText);
          Map<String, dynamic> eventData = jsonDecode(responseText);

          // print(eventData);
          String userIntent = eventData['User_Intent'] ?? 'Undefined';
          String eventDate = eventData['Date'] ?? 'Undefined';
          String startTime = eventData['Start_Time'] ?? 'Undefined';
          String endTime = eventData['End_Time'] ?? 'Undefined';
          String eventName = eventData['Event_name'] ?? 'Undefined';

          print("User Intent: $userIntent");
          print("Event Date: $eventDate");
          print("Event Start Time: $startTime");
          print("Event End Time: $endTime");
          print("Event Name: $eventName");

          try {
            if (userIntent == "Add_Event") {
            // Parse date and time strings into DateTime objects
            DateTime startDate = DateTime.parse("2024-10-16"); // Replace with parsed date
            DateTime startTime = DateTime.parse("2024-10-16 17:00"); // Replace with parsed time
            DateTime endTime = startTime.add(Duration(hours: 1)); // Set event to 1 hour

            // Call Google Calendar API to add event
            await googleCalendarService.addEvent(eventName, startDate, startTime, endTime);
          }
          } catch (e) {
            print("Failed to add Event to calendar: $e");
          }
          ChatMessage newMessage = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: "Intent: $userIntent, Date: $eventDate, Start Time: $startTime, End Time: $endTime, Event: $eventName",
          );
          setState(() {
            messages = [newMessage, ...messages];
          });
        } catch (e) {
          print("Failed to parse JSON response from Gemini: $e");
        }
      }
    } catch (e) {
      print("Failed to retreive the prompt $e");
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  }
}