
import 'package:flutter/material.dart';
import 'main_screen.dart';

class HistoryPage extends StatelessWidget {
  final List<Medication> myMedications;

  const HistoryPage({
    super.key,
    required this.myMedications,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 186, 208, 241),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'History of Medications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: myMedications.isEmpty
                  ? const Center(
                      child: Text(
                        'No medication history available yet.\n'
                        'Add a medication to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: myMedications.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final med = myMedications[index];

                        final String status;
                        final Color statusColor;
                        final String detail;

                        if (med.missed) {
                          status = 'MISSED';
                         
                          statusColor = Colors.red;
                          detail = '❌ Dose window expired CONTACT CAREGIVER USING NUMBER ON HOME SCREEN' ;
                        } else if (med.taken) {
                          status = 'TAKEN';
                          statusColor = Colors.green;
                          detail = '✅ Medication taken';
                        } else if (med.verified) {
                          status = 'VERIFIED';
                          statusColor = Colors.green;
                          detail = '✅ Verification completed';
                        } else {
                          status = 'PENDING';
                          statusColor = Colors.grey;
                          detail = '⏳ Awaiting verification';
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${med.dosage} • ${med.type}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Scheduled: ${med.time}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    detail,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (med.takenTime != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Recorded: '
                                      '${med.takenTime!.month}/'
                                      '${med.takenTime!.day}/'
                                      '${med.takenTime!.year} '
                                      '${med.takenTime!.hour}:'
                                      '${med.takenTime!.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                status,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
